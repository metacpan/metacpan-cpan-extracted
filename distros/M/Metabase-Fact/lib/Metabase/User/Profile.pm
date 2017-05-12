use 5.006;
use strict;
use warnings;

package Metabase::User::Profile;

our $VERSION = '0.025';

use Carp ();
use Data::GUID guid_string => { -as => '_guid' };

use Metabase::Report;
our @ISA = qw/Metabase::Report/;

__PACKAGE__->load_fact_classes;

#--------------------------------------------------------------------------#
# public API
#--------------------------------------------------------------------------#

sub create {
    my ( $class, @args ) = @_;
    my $args = $class->__validate_args(
        \@args,
        {
            full_name     => 1,
            email_address => 1,
        }
    );

    # resource string must reference our own guid, so pregenerate it
    my $guid    = lc _guid();
    my $profile = $class->open(
        guid     => $guid,
        resource => "metabase:user:$guid",
    );

    # we are our own creator
    $profile->set_creator( $profile->resource );

    # add facts
    $profile->add( 'Metabase::User::FullName'     => $args->{full_name} );
    $profile->add( 'Metabase::User::EmailAddress' => $args->{email_address} );
    $profile->close;
    return $profile;
}

#--------------------------------------------------------------------------#
# internals
#--------------------------------------------------------------------------#

sub validate_resource {
    my ($self)   = shift;
    my $resource = $self->SUPER::validate_resource(@_);
    my ($guid)   = $resource->guid;
    Carp::confess "resource guid differs from fact guid" if $guid ne $self->guid;
    return $resource;
}

sub report_spec {
    return {
        'Metabase::User::FullName'     => '1',
        'Metabase::User::EmailAddress' => '1+',
    };
}

1;

# ABSTRACT: Metabase report class for user-related facts

__END__

=pod

=encoding UTF-8

=head1 NAME

Metabase::User::Profile - Metabase report class for user-related facts

=head1 VERSION

version 0.025

=head1 SYNOPSIS

  use Metabase::User::Profile;

  my $profile = Metabase::User::Profile->create(
    full_name     => 'John Doe',
    email_address => 'jdoe@example.com',
  );

=head1 DESCRIPTION

Metabase report class encapsulating Facts about a metabase user

=head1 USAGE

=head2 The short way

  my $profile = Metabase::User::Profile->create(
    full_name     => 'John Doe',
    email_address => 'jdoe@example.com',
  );

=head2 The long way

  my $profile = Metabase::User::Profile->open(
    resource => 'metabase:user:b66c7662-1d34-11de-a668-0df08d1878c0'
    creator  => 'metabase:user:b66c7662-1d34-11de-a668-0df08d1878c0'
  );

  $profile->add( 'Metabase::User::EmailAddress' => 'jdoe@example.com' );
  $profile->add( 'Metabase::User::FullName'     => 'John Doe' );
    
  $profile->close;

=head1 METHODS

=head2 create

  my $new_profile = Metabase::User::Profile->create(%arg);

This method creates a new user profile object from the given parameters.

Valid parameters include:

  full_name      - the user's full name
  email_address  - the user's email address

=head2 load

  my $profile = Metabase::User::Profile->load($filename);

This method loads a profile from disk and returns it.

=head2 save

  $profile->save($filename);

This method writes out the profile to a file.  If the file cannot be written,
an exception is raised.  If the save is successful, a true value is returned.

=head1 BUGS

Please report any bugs or feature using the CPAN Request Tracker.  
Bugs can be submitted through the web interface at 
L<http://rt.cpan.org/Dist/Display.html?Queue=Metabase-Fact>

When submitting a bug or request, please include a test-file or a patch to an
existing test-file that illustrates the bug or desired feature.

=head1 AUTHORS

=over 4

=item *

David Golden <dagolden@cpan.org>

=item *

Ricardo Signes <rjbs@cpan.org>

=item *

H.Merijn Brand <hmbrand@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
