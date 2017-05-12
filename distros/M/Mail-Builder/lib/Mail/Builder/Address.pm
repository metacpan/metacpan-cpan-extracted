# ============================================================================
package Mail::Builder::Address;
# ============================================================================

use namespace::autoclean;
use Moose;
use Mail::Builder::TypeConstraints;

use Carp;

use Email::Valid;

our $VERSION = $Mail::Builder::VERSION;

has 'email' => (
    is              => 'rw',
    isa             => 'Mail::Builder::Type::EmailAddress',
    required        => 1,
);

has 'name' => (
    is              => 'rw',
    isa             => 'Str',
    predicate       => 'has_name',
);

has 'comment' => (
    is              => 'rw',
    isa             => 'Str',
    predicate       => 'has_comment',
);

=encoding utf8

=head1 NAME

Mail::Builder::Address - Module for handling e-mail addresses

=head1 SYNOPSIS

  use Mail::Builder;
  
  my $mail = Mail::Builder::Address->new('mightypirate@meele-island.mq','Gaybrush Thweedwood');
  # Now correct type in the display name and address
  $mail->name('Guybrush Threepwood');
  $mail->email('verymightypirate@meele-island.mq');
  $mail->comment('Mighty Pirate (TM)');
  
  # Serialize
  print $mail->serialize;
  
  # Use the address as a recipient for  Mail::Builder object
  $mb->to($mail); # Removes all other recipients
  OR
  $mb->to->add($mail); # Adds one more recipient (without removing the existing ones)

=head1 DESCRIPTION

This is a simple module for handling e-mail addresses. It can store the address
and an optional display name.

=head1 METHODS

=head2 Constructor

=head3 new

 Mail::Builder::Address->new(EMAIL[,DISPLAY NAME[,COMMENT]]);
 OR
 Mail::Builder::Address->new({
     email      => EMAIL,
     [ name     => DISPLAY NAME, ]
     [ comment  => COMMENT, ]
 })
 OR
 my $email = Email::Address->parse(...);
 Mail::Builder::Address->new($email);

Simple constructor

=cut


around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;
    my @args = @_;

    my $args_length = scalar @args;
    my %params;

    if ($args_length == 1) {
        if (blessed $args[0] && $args[0]->isa('Email::Address')) {
            $params{email} = $args[0]->address;
            $params{name} = $args[0]->phrase;
            $params{comment} = $args[0]->comment;
        } elsif (ref $args[0] eq 'HASH') {
            return $class->$orig($args[0]);
        } elsif (ref $args[0] eq 'ARRAY') {
            $params{email} = $args[0]->[0];
            $params{name} = $args[0]->[1];
            $params{comment} = $args[0]->[2];
        } else {
            $params{email} = $args[0];
        }
    } elsif ($args_length == 2
        && $args[0] ne 'email') {
        $params{email} = $args[0];
        $params{name} = $args[1];
    } elsif ($args_length == 3) {
        $params{email} = $args[0];
        $params{name} = $args[1];
        $params{comment} = $args[2];
    } else {
        return $class->$orig(@args);
    }

    delete $params{name}
        unless defined $params{name} && $params{name} !~ /^\s*$/;
    delete $params{comment}
        unless defined $params{comment} && $params{comment} !~ /^\s*$/;

    return $class->$orig(\%params);
};

sub address { ## no critic(RequireArgUnpacking)
    my $self = shift;
    return $self->email(@_);
}

=head2 Public Methods

=head3 serialize

Prints the address as required for creating the e-mail header.

=cut

sub serialize {
    my ($self) = @_;

    return $self->email
        unless $self->has_name;

    my $name = $self->name;
    $name =~ s/"/\\"/g;

    my $encoded = Mail::Builder::Utils::encode_mime($name);
    $encoded = qq["$encoded"]
        unless $encoded =~ /=\?/;
    my $return = sprintf '%s <%s>',$encoded,$self->email;
    $return .= ' '.Mail::Builder::Utils::encode_mime($self->comment)
        if $self->has_comment;

    return $return;
}

=head3 compare

 $obj->compare(OBJECT);
 or
 $obj->compare(E-MAIL);

Checks if two address objects contain the same e-mail address. Returns true
or false. The compare method does not check if the address names of the
two objects are identical.

Instead of a C<Mail::Builder::Address> object you can also pass a
scalar value representing the e-mail address.

=cut

sub compare {
    my ($self,$compare) = @_;

    return 0
        unless (defined $compare);

    if (blessed($compare)) {
        return 0 unless $compare->isa(__PACKAGE__);
        return (uc($self->email) eq uc($compare->email)) ? 1:0;
    } else {
        return ( uc($compare) eq uc($self->{email}) ) ? 1:0;
    }
}

sub empty {
    croak('DEPRECATED')
}

__PACKAGE__->meta->make_immutable;

1;

=head2 Accessors

=head3 name

Display name

=head3 email

E-mail address. Will be checked with L<Email::Valid>
L<Email::Valid> options may be changed by setting the appropriate values
in the %Mail::Builder::TypeConstraints::EMAILVALID hash.

Eg. if you want to disable the check for valid TLDs you can set the 'tldcheck'
option (without dashes 'tldcheck' and not '-tldcheck'):

 $Mail::Builder::TypeConstraints::EMAILVALID{tldcheck} = 0;

Required

=head3 comment

Comment

=head1 AUTHOR

    Maroš Kollár
    CPAN ID: MAROS
    maros [at] k-1.com
    http://www.k-1.com

=cut
