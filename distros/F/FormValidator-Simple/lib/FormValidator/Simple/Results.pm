package FormValidator::Simple::Results;
use strict;
use base qw/Class::Accessor::Fast/;
use FormValidator::Simple::Result;
use FormValidator::Simple::Exception;
use FormValidator::Simple::Constants;
use Tie::IxHash;
use List::MoreUtils;

__PACKAGE__->mk_accessors(qw/_records message/);

sub new {
    my $class = shift;
    my $self  = bless { }, $class;
    $self->_init(@_);
    return $self;
}

sub _init {
    my ($self, %args) = @_;
    my %hash = ();
    tie (%hash, 'Tie::IxHash');
    $self->_records(\%hash);

    my $messages = delete $args{messages};
    $self->message($messages);
}

sub messages {
    my ($self, $action) = @_;
    my @messages = ();
    my $keys = $self->error;
    foreach my $key ( @$keys ) {
        my $types = $self->error($key);
        foreach my $type ( @$types ) {
            push @messages,
                $self->message->get($action, $key, $type);
        }
    }
    @messages = List::MoreUtils::uniq(@messages);
    return \@messages;
}

sub field_messages {
    my ($self, $action) = @_;
    my $messages = {};
    my $keys = $self->error;
    foreach my $key ( @$keys ) {
        $messages->{$key} = [];
        my $types = $self->error($key);
        foreach my $type ( @$types ) {
            my $message = $self->message->get($action, $key, $type);
            unless ( List::MoreUtils::any { $_ eq $message } @{ $messages->{$key} } ) {
                push @{ $messages->{$key} }, $message;
            }
        }
    }
    return $messages;
}

sub register {
    my ($self, $name) = @_;
    $self->_records->{$name}
        ||= FormValidator::Simple::Result->new($name);
}

sub record {
    my ($self, $name) = @_;
    $self->register($name)
    unless exists $self->_records->{$name};
    return $self->_records->{$name};
}

sub set_result {
    my ($self, $name, $type, $result) = @_;
    $self->register($name);
    $self->record($name)->set($type, $result);
}

sub set_invalid {
    my ($self, $name, $type) = @_;
    unless ($name && $type) {
        FormValidator::Simple::Exception->throw(
            qq/set_invalid needs two arguments./
        );
    }
    $self->set_result($name, $type, FALSE);
}

sub success {
    my $self = shift;
    return ($self->has_missing or $self->has_invalid) ? FALSE : TRUE;
}

sub has_error {
    my $self = shift;
    return ($self->has_missing or $self->has_invalid) ? TRUE : FALSE;
}

sub has_blank {
    my $self = shift;
    foreach my $record ( values %{ $self->_records } ) {
        return TRUE if $record->is_blank;
    }
    return FALSE;
}

*has_missing = \&has_blank;

sub has_invalid {
    my $self = shift;
    foreach my $record ( values %{ $self->_records } ) {
        return TRUE if $record->is_invalid;
    }
    return FALSE;
}

sub valid {
    my ($self, $name) = @_;
    if ($name) {
        return unless exists $self->_records->{$name};
        return $self->record($name)->is_valid
             ? $self->record($name)->data : FALSE;
    }
    else {
        my %valids
            = map { ( $_->name, $_->data ) } grep { $_->is_valid } values %{ $self->_records };
        return \%valids;
    }
}

sub error {
    my ($self, $name, $constraint) = @_;
    if ($name) {
        if ($constraint) {
            if ($constraint eq 'NOT_BLANK') {
            return $self->record($name)->is_blank
                ? TRUE
                : FALSE
                ;
            }
            return $self->record($name)->is_invalid_for($constraint)
                ? TRUE
                : FALSE
                ;
        }
        else {
            if ($self->record($name)->is_blank) {
                return wantarray ? 'NOT_BLANK' : ['NOT_BLANK'];
            }
            elsif ($self->record($name)->is_invalid) {
                my $constraints = $self->record($name)->constraints;
                my @invalids = grep { !$constraints->{$_} } keys %$constraints;
                return wantarray ? @invalids : \@invalids;
            }
            else {
                return FALSE;
            }
        }
    }
    else {
        my @errors = 
        map { $_->name } grep { $_->is_blank or $_->is_invalid } values %{ $self->_records };
        return wantarray ? @errors : \@errors;
    }
}

sub blank {
    my ($self, $name) = @_;
    if ($name) {
        return $self->record($name)->is_blank ? TRUE : FALSE;
    }
    else {
        my @blanks
            = map { $_->name } grep { $_->is_blank } values %{ $self->_records };
        return wantarray ? @blanks : \@blanks;
    }
}

*missing = \&blank;

sub invalid {
    my ($self, $name, $constraint) = @_;
    if ($name) {
        if ($constraint) {
            $self->record($name)->is_invalid_for($constraint)
                ? TRUE : FALSE;
        }
        else {
            if ($self->record($name)->is_invalid) {
                my $constraints = $self->record($name)->constraints;
                my @invalids = grep { !$constraints->{$_} } keys %$constraints;
                return wantarray ? @invalids : \@invalids;
            }
            else {
                return FALSE;
            }
        }
    }
    else {
        my @invalids
            = map { $_->name } grep { $_->is_invalid } values %{ $self->_records };
        return wantarray ? @invalids : \@invalids;
    }
}

sub clear {
  %{shift->_records} = ();
}

1;
__END__

=head1 NAME

FormValidator::Simple::Results - results of validation

=head1 SYNOPSIS

    my $results = FormValidator::Simple->check( $req => [
        name  => [qw/NOT_BLANK ASCII/, [qw/LENGTH 0 10/] ],
        email => [qw/NOT_BLANK EMAIL_LOOSE/, [qw/LENGTH 0 30/] ],
    ] );

    if ( $results->has_error ) {
        foreach my $key ( @{ $results->error() } ) {
            foreach my $type ( @{ $results->erorr($key) } ) {
                print "invalid: $key - $type \n";
            }
        }
    }

=head1 DESCRIPTION

This is for handling resuls of FormValidator::Simple's check.

This object behaves like Data::FormValidator's results object, but
has some specific methods.

=head1 CHECK RESULT

=over 4

=item has_missing

If there are missing values ( failed in validation 'NOT_BLANK' ), this method returns true.

    if ( $results->has_missing ) {
        ...
    }

=item has_invalid

If there are invalid values ( failed in some validations except 'NOT_BLANK' ), this method returns true.

    if ( $results->has_invalid ) {
        ...
    }

=item has_error

If there are missing or invalid values, this method returns true.

    if ( $results->has_error ) {
        ...
    }

=item success

inverse of has_error

    unless ( $resuls->success ) {
        ...
    }

=back

=head1 ANALYZING RESULTS

=head2 missing

=over 4

=item no argument

When you call this method with no argument, it returns keys failed 'NOT_BLANK' validation.

    my $missings = $results->missing;
    foreach my $missing_data ( @$missings ) {
        print $missing_data, "\n";
    }
    # -- print out, for example --
    # name
    # email

=item key

When you call this method with key-name, it returnes true if the value of the key is missing.

    if ( $results->missing('name') ) {
        print "name is empty! \n";
    }

=back

=head2 invalid

=over 4

=item no argument

When you call this method with no argument, it returns keys that failed some validation except 'NOT_BLANK'.

    my $invalids = $results->invalid;
    foreach my $invalid_data ( @$invalids ) {
        print $invalid_data, "\n";
    }
    # -- print out, for example --
    # name
    # email

=item key

When you call this method with key-name, it returns names of failed validation.

    my $failed_validations = $results->invalid('name');
    foreach my $validation ( @$failed_validations ) {
        print $validation, "\n";
    }
    # -- print out, for example --
    # ASCII
    # LENGTH

=item key and validation-name

When you call this method with key-name, it returns false if the value has passed the validation.

    if ( $results->invalid( name => 'LENGTH' ) ) {
        print "name is wrong length! \n";
    }

=back

=head2 error

This doesn't distinguish 'missing' and 'invalid'. You can use this like 'invalid' method,
but this consider 'NOT_BLANK' same as other validations.

    my $error_keys = $results->error;

    my $failed_validation = $resuls->error('name');
    # this includes 'NOT_BLANK'

    if ( $results->error( name => 'NOT_BLANK' ) ) {
        print "name is missing! \n";
    }

    if ( $results->error( name => 'ASCII' ) ) {
        print "name should be ascii code! \n";
    }

=head1 SEE ALSO

L<FormValidator::Simple>

=head1 AUTHOR

Lyo Kato E<lt>lyo.kato@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

This library is free software.
You can redistribute it and/or modify it under the same terms as perl itself.

=cut

