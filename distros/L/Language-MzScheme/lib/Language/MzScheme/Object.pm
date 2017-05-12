package Language::MzScheme::Object;
@_p_Scheme_Object::ISA = __PACKAGE__;

use strict;
use vars '%Proc';
use constant S => "Language::MzScheme";
use overload (
    'bool'      => \&to_bool,
    '""'        => \&to_string,
    '0+'        => \&to_number,
    '!'         => \&to_negate,
    '&{}'       => \&to_coderef,
    '%{}'       => \&to_hashref,
    '@{}'       => \&to_arrayref,
    '*{}'       => \&to_globref,
    '${}'       => \&to_scalarref,
    '<>'        => \&read,
    '++'        => \&increment,
    '--'        => \&decrement,
    fallback    => 1,
);

=head1 NAME

Language::MzScheme::Object - MzScheme value object

=head1 SYNOPSIS

    use Language::MzScheme;
    my $env = Language::MzScheme->new;
    my $obj = $env->lookup('cons');
    # ...

=head1 OVERLOADS

Following operators are overloaded for this class:

    bool "" 0+ ! &{} %{} @{} *{} ${} <>

=head1 METHODS

Under construction.

=head2 Converting into Perl values

    to_bool to_string to_number to_negate
    to_coderef to_hashref to_arrayref to_globref to_scalarref
    as_write as_display as_perl_data

=head2 List object methods

    car cdr cadr caar cddr caadr

=head2 Port object methods

    read write read-char write-char

=head2 Environment dispatchers

    eval apply lambda lookup
    perl_do perl_eval perl_require perl_use perl_no

=head2 Miscellanous Utilities

    env bless isa

=cut

foreach my $proc (qw( car cdr cadr caar cddr )) {
    no strict 'refs';
    my $code = S."::SCHEME_\U$proc";
    *$proc = sub { $_[0]->bless($code->($_[0])) };
}

foreach my $proc (qw( caddr read write )) {
    no strict 'refs';
    my $code = S."::scheme_$proc";
    *$proc = sub { $_[0]->bless($code->($_[0])) };
}

foreach my $proc (qw( read-char write-char )) {
    no strict 'refs';
    my $sym = $proc;
    $sym =~ s/\W/_/g;
    *$sym = sub { $_[0]->apply($proc, $_[0]) };
}

foreach my $proc (qw(
    eval apply lambda lookup val sym
    perl_do perl_eval perl_require perl_use perl_no
)) {
    no strict 'refs';
    *$proc = sub {
        my $env = shift(@_)->env;
        $env->can($proc)->($env, @_);
    };
}

sub new {
    my $self = shift;
    $self->bless( S->from_perl_scalar($_[0]) );
}

sub to_bool {
    my $self = shift;
    !S->UNDEFP($self);
}

sub to_string {
    my $self = shift;
    S->STRSYMP($self) ? S->STRSYM_VAL($self) :
    S->CHARP($self)   ? S->CHAR_VAL($self) :
    S->UNDEFP($self)  ? '' :
                        $self->as_display;
}

sub to_number {
    my $self = shift;
    S->UNDEFP($self) ? 0 : $self->as_display;
}

sub to_negate {
    my $self = shift;
    S->UNDEFP($self) ? '#t' : undef;
}

sub env {
    my $self = shift;
    $Language::MzScheme::Env::Objects{S->REFADDR($self)}
        ||= $Language::MzScheme::Env::Objects{0}
            or die "Cannot find associated environment";
}

sub bless {
    my ($self, $obj) = @_;
    $Language::MzScheme::Env::Objects{S->REFADDR($obj)}||=
        $Language::MzScheme::Env::Objects{S->REFADDR($self)} if defined $obj;
    return $obj;
}

sub to_coderef {
    my $self = shift;

    S->PROCP($self) or die "Value $self is not a CODE";

    $Proc{+$self} ||= sub { $self->apply($self, @_) };
}

my $Cons;
sub to_hashref {
    my $self = shift;
    my $alist = (S->HASHTP($self)) ? $self->apply(
        'hash-table-map',
        $self,
        $Cons ||= $self->lookup('cons'),
    ) : $self;

    my %rv;
    while (my $obj = $alist->car) {
        $rv{as_perl_data($obj->car)} = $obj->cdr;
        $alist = $alist->cdr;
    }
    return \%rv;
}

sub to_arrayref {
    my $self = shift;

    # XXX - rewrite in XS
    if (S->VECTORP($self)) {
        $self = S->vector_to_list($self);
        #my $vec = S->VEC_BASE($self);
        #my $env = $self->env;
        #$Language::MzScheme::Env::Objects{+$_}||=$env for @$vec;
        #return $vec;
    }

    return [
        map +($self->car, $self = $self->cdr)[0],
            1..S->proper_list_length($self)
    ];
}

sub to_scalarref {
    my $self = shift;
    return \S->BOX_VAL($self);
}

sub as_display {
    my $self = shift;
    my $out = S->make_string_output_port;
    S->display($self, $out);
    return S->get_string_output($out);
}

sub as_write {
    my $self = shift;
    my $out = S->make_string_output_port;
    S->write($self, $out);
    return S->get_string_output($out);
}

sub as_perl_data {
    my $self = shift;

    return $self unless UNIVERSAL::isa($self, __PACKAGE__);

    if ( S->PERLP($self) ) {
        return S->to_perl_scalar($self);
    }
    if ( S->CODE_REFP($self) ) {
        return $self->to_coderef;
    }
    elsif ( S->HASHTP($self) ) {
        my $hash = $self->to_hashref;
        $hash->{$_} = as_perl_data($hash->{$_}) for keys %$hash;
        return $hash;
    }
    elsif ( S->ARRAY_REFP($self) ) {
        return [ map as_perl_data($_), @{$self->to_arrayref} ];
    }
    elsif ( S->GLOB_REFP($self) ) {
        return $self; # XXX -- doesn't really know what to do
    }
    elsif ( S->SCALAR_REFP($self) ) {
        return \as_perl_data(${$self->to_scalarref});
    }
    elsif ( S->UNDEFP($self) ) {
        return undef;
    }
    else {
        $self->to_string;
    }
}

sub isa {
    my ($self, $type) = @_;
    my $p = S->can("MZSCHEME_${type}_REFP") or return $self->SUPER::isa($type);
    return $p->($self);
}

sub increment {
    my $scalar = as_perl_data($_[0]);
    $scalar++;
    $_[0] = $_[0]->new($scalar);
}

sub decrement {
    my $scalar = as_perl_data($_[0]);
    $scalar--;
    $_[0] = $_[0]->new($scalar);
}

1;

__END__

=head1 SEE ALSO

L<Language::MzScheme>, L<Language::MzScheme::Env>

=head1 AUTHORS

Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>

=head1 COPYRIGHT

Copyright 2004 by Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
