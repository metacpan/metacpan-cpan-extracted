package Log::Dispatch::FogBugz;

use warnings;
use strict;
use Log::Dispatch::Output;
use base qw/Log::Dispatch::Output/;
use Carp qw{croak};

use LWP::UserAgent;

our $VERSION = '0.1';

sub new {
  my $proto = shift;
  my $class = ref $proto || $proto;

  my %p = @_;

  my $self = bless {}, $class;

  $self->_basic_init(%p);
  $self->_init(%p);
  return $self;
}

sub log_message {
    my $self = shift;
    my %p = @_;

    $self->{form}{Description} = $self->{params}{DescriptionPrefix} ? $self->{params}{DescriptionPrefix} : '';
    $p{message} =~ $self->{params}{DescriptionRegex};

    if ( $1 ) {
        $self->{form}{Description} .= $1;
    }

    $self->{form}{Extra} = $p{message};

    my $ua = LWP::UserAgent->new;
    my $resp = $ua->post($self->{params}{URL}, $self->{form});
}

sub _init {
    my ( $self, %opts ) = @_;
    $self->{params} = \%opts;

    foreach my $req ( qw/URL Project User Area/ ) {
        croak "Required configuration parameter `$req` was not defined" unless defined $opts{$req};
    }

    unless ( $opts{DescriptionPrefix} or $opts{DescriptionRegex} ) {
        croak "One of DescriptionPrefix or DescriptionRegex options are required";
    }

    if ( $opts{DescriptionRegex} and ref($opts{DescriptionRegex}) ne 'Regexp' ) {
        croak "DescriptionRegex must be a compiled regex (use qr{})";
    }

    $self->{form} = {
        ScoutProject      => $opts{Project}
      , ScoutUserName     => $opts{User}
      , ScoutArea         => $opts{Area}
      , ForceNewBug       => ( $opts{ForceNewBug} || 0 )
      , FriendlyResponse  => 0
    };
}

__END__

=head1 NAME

Log::Dispatch::FogBugz - Log::Dispatch appender for sending log messages to the FogBugz bug tracking system

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Log::Dispatch::FogBugz;

    my $log = Log::Dispatch::FogBugz->new
        (
            URL               => 'http://fogbugz.bar.com/scoutSubmit.php'
          , Project           => 'Bar'
          , Area              => 'Baz'
          , ForceNewBug       => 0
          , User              => 'Bob the Submitter'
          , DescriptionPrefix => 'Log4perl error!'
          , DescriptionRegex  => qr/> (.+)$/
        );
    $log->log( message => "FATAL> main::do_baz(23) - Something really bad happened here", level => 'fatal' );

=head1 DESCRIPTION

This is a subclass of Log::Dispatch::Output that implements sending log messages to a FogBugz (http://fogcreek.com/fogbugz) bug tracking system.

=head1 METHODS

=over 4

=item * new

This method takes configuration parameters as follows:

=over 8

=item * URL ($) Required

Fully qualified url for fogbugz scoutsubmit script.

=item * Project ($) Required

The project to create this bug message in.

=item * Area ($) Required

The area within the given project.

=item * ForceNewBug (0|1)

Whether or not to force the creation of a new bug

=item * User ($) Required

Username to use when submitting.

=item * DescriptionPrefix ($) Optionally Required

String to use as either a prefix or a full description for the error.  One of DescriptionRegex or DescriptionPrefix are required.

=item * DescriptionRegex (Regex) Optionally Required

Capturing regex to use to dynamically pull out the description.  $1 will be used as the description.  Will be concatenated to DescriptionPrefix if set.  One of DescriptionRegex or DescriptionPrefix are required.

=back

=item * log_message( level => $, message => $ )

Sends the message if the level is greater than or equal to the object's minimum level.

=back

=head1 SEE ALSO

L<Log::Log4perl::Config|Log::Log4perl::Config>,
L<Log::Log4perl::Appender|Log::Log4perl::Appender>,
L<Log::Dispatch>,

=head1 AUTHOR

DIMARTINO, C<< <chris.dimartino at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-log-dispatch-fogbugz at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Log-Dispatch-FogBugz>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Log::Dispatch::FogBugz


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Log-Dispatch-FogBugz>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Log-Dispatch-FogBugz>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Log-Dispatch-FogBugz>

=item * Search CPAN

L<http://search.cpan.org/dist/Log-Dispatch-FogBugz/>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to the authors of Log::Log4perl and Log::Dispatch modules.

=head1 COPYRIGHT & LICENSE

Copyright 2009 CDIMARTINO, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Log::Dispatch::FogBugz
