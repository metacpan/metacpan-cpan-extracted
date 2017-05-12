package Devel::Cover::Report::OwnServer;

use 5.010001;
use strict;
use warnings;
use version; our $VERSION = qv( sprintf '0.4.%d', q$Rev: 1 $ =~ /\d+/gmx );

use Getopt::Long;
use HTTP::Tiny;
use JSON::PP qw( decode_json encode_json );

my $URI_TEMPLATE = 'http://localhost:5000/coverage/report/%s';

# Private subroutines
my $run = sub {
   my $cmd = shift; return qx( $cmd );
};

my $get_git_info = sub {
   my ($dist, $version) = @_;

   my ($branch) =  grep { m{ \A \* }mx } split "\n", $run->( 'git branch' );
       $branch  =~ s{ \A \* \s* }{}mx;
   my $remotes  =  [ map    { my ($name, $url) = split q( ), $_;
                              +{ name => $name, url => $url } }
                     split m{ \n }mx, $run->( 'git remote -v' ) ];

   return { author_name     => $run->( 'git log -1 --pretty=format:"%aN"' ),
            author_email    => $run->( 'git log -1 --pretty=format:"%ae"' ),
            branch          => $branch,
            commit          => $run->( 'git log -1 --pretty=format:"%H"' ),
            committer_name  => $run->( 'git log -1 --pretty=format:"%cN"' ),
            committer_email => $run->( 'git log -1 --pretty=format:"%ce"' ),
            coverage_token  => $ENV{COVERAGE_TOKEN} // '[?]',
            dist_name       => $dist,
            message         => $run->( 'git log -1 --pretty=format:"%s"' ),
            remotes         => $remotes,
            version         => $version, };
};

# Public methods
sub get_options {
   my ($self, $opt) = @_;

   $opt->{option}->{uri_template} = $ENV{COVERAGE_URI} // $URI_TEMPLATE;

   GetOptions( $opt->{option}, 'uri_template=s' )
      or die 'Invalid command line options';

   return;
}

sub report {
   my (undef, $db, $config) = @_;

   my %options = map  { $_ => 1 }
                 grep { not m{ path|time }mx } $db->all_criteria, 'force';

   $db->calculate_summary( %options );

   my $dist    = (($db->runs)[ 0 ])->name;
   my $version = (($db->runs)[ 0 ])->version;
   # Use the hash since there is a bug: use of uninitialized value $file in
   # hash element at Devel/Cover/DB.pm line 324.
   my $report  = { info    => $get_git_info->( $dist, $version ),
                   summary => $db->{summary} };
   my $http    = HTTP::Tiny->new
      ( default_headers => { 'Content-Type' => 'application/json' } );
   my $uri     = sprintf $config->{option}->{uri_template}, lc $dist;
   my $resp    = $http->post( $uri, { content => encode_json $report } );

   if ($resp->{success}) {
      my $content = decode_json $resp->{content};

      print $content->{message}."\n";
   }
   else {
      warn 'Coverage upload status '.$resp->{status}.': '.$resp->{reason}."\n";
   }

   return;
}

1;

__END__

=pod

=encoding utf-8

=head1 Name

Devel::Cover::Report::OwnServer - Post test coverage summary to selected service

=head1 Synopsis

   perl Build.PL
   ./Build
   template="https://your_coverage_server/coverage/report/%s"
   cover --uri_template ${template} -test -report ownServer

   # OR

   export COVERAGE_URI="https://your_coverage_server/coverage/report/%s"
   perl Build.PL && ./Build && cover -test -report ownServer

=head1 Description

Post test coverage summary to selected service

=head1 Configuration and Environment

Either the C<uri_template> option or the C<COVERAGE_URI> environment variable
should point to your coverage server. One string will be interpolated; the
lower-cased distribution name. The default template is;

   http://localhost:5000/coverage/report/%s

The value of the environment variable C<COVERAGE_TOKEN> is sent to the server
along with the coverage report summary. The token is used to authenticate
post from the integration server to the coverage server. For Travis-CI
use the command

   travis encrypt COVERAGE_TOKEN=<insert your token here>

and place the output in your F<.travis.yml> file

   env:
     global:
       - secure: <base64 encoded output from travis encrypt>

This Travis encrypt command must be run from within the working copy of
the repository as it detects the repository name and uses it to salt
the encryption

=head1 Subroutines/Methods

=head2 C<get_options>

Adds C<uri_template> to the command line options

=head2 C<report>

Send the test coverage summary report to the selected service

=head1 See Also

=over 3

=item C<http://github.com/pjfl/p5-coverage-server>

An example implementation of a coverage server that accepts the report
summaries posted to it by this module and serves C<SVG> coverage badges

=back

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Getopt::Long>

=item L<HTTP::Tiny>

=item L<JSON::PP>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module. Please report problems to
http://rt.cpan.org/NoAuth/Bugs.html?Dist=Devel-Cover-Report-OwnServer.
Patches are welcome

=head1 Acknowledgements

Larry Wall - For the Perl programming language

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2016 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:
