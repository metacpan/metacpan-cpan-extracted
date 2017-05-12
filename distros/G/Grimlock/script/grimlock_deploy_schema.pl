#!/usr/bin/env perl
 
use strict;
use warnings;
 
use feature ":5.10";
 
use FindBin;
use lib "$FindBin::Bin/../lib";
use Grimlock::Schema;
use Config::JFDI;
 
my $config = Config::JFDI->new( name =>'Grimlock::Web' );
my $config_hash  = $config->get;
my $connect_info = $config_hash->{"Model::Database"}{"connect_info"};
my $schema       = Grimlock::Schema->connect($connect_info);
 
sub install {
  $schema->deploy;
}
 
sub upgrade {
  say "work in progress";
}
 
sub current_version {
  say "work in progress"
}
 
sub help {
say <<'OUT';
usage:
  install
  upgrade
  current-version
OUT
}
 
help unless $ARGV[0];
 
given ( $ARGV[0] ) {
    when ('install')         { install()         }
    when ('upgrade')         { upgrade()         }
    when ('current-version') { current_version() }
}


=head1 NAME
grimlock_deploy_schema.pl - MAKE DATABASE FOR GRIMLOCK BLOG

=head1 SYNOPSIS

grimlock_deploy_schema.pl install

=head1 DESCRIPTION

MAKE DATABASE FOR GRIMLOCK BLOG SO IT CAN SAVE BLOGS ABOUT CESIUM SALAMI AND BERYLLIUM BALONEY

=head1 AUTHORS

ME, GRIMLOCK!

=head1 COPYRIGHT

ME GRIMLOCK WANT SHARE BEAUTIFUL SOFTWARE ME WRITE WITH WORLD.  ME GRIMLOCK SAY THIS SOFTWARE RELEASE UNDER ARTISTIC LICENSE.

SEE L<perlartistic>.

=cut

