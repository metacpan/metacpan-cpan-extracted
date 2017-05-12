package Dist::Zilla::Role::MetaCPANInterfacer;

our $VERSION = '0.97'; # VERSION
# ABSTRACT: something that will interact with MetaCPAN's API

use sanity;

use Moose::Role;
use CHI;
use WWW::Mechanize::Cached::GZip;
use HTTP::Tiny::Mech;
use MetaCPAN::API;

use POSIX ();
use File::Temp qw(tempdir);  # 'tmpnam' defined both here and POSIX
use Path::Class;
use File::HomeDir;
use Scalar::Util qw{blessed};
use List::AllUtils qw{min};

use namespace::clean;

has mcpan => (
   is      => 'rw',
   isa     => 'Object',
   lazy    => 1,
   default => sub {
      MetaCPAN::API->new( ua => $_[0]->mcpan_ua );
   },
);

has mcpan_ua => (
   is      => 'rw',
   isa     => 'Object',
   lazy    => 1,
   default => sub {
      HTTP::Tiny::Mech->new( mechua => $_[0]->mcpan_mechua );
   },
);

has mcpan_mechua => (
   is      => 'rw',
   isa     => 'Object',
   lazy    => 1,
   default => sub {
      $_[0]->_mcpan_set_agent_str(
         WWW::Mechanize::Cached::GZip->new( cache => $_[0]->mcpan_cache )
      );
   },
);

has mcpan_cache => (
   is      => 'rw',
   isa     => 'Object',
   lazy    => 1,
   default => sub {
      # don't use $HOME if we are in the middle of testing
      my $home_dir = $ENV{HARNESS_ACTIVE} ? tempdir(CLEANUP => 1) : File::HomeDir->my_home;
      my $root_dir = dir($home_dir)->subdir('.dzil', '.webcache');
      CHI->new(
         namespace  => 'MetaCPAN',
         driver     => 'File',
         expires_in => '1d',
         root_dir   => $root_dir->stringify,

         # https://rt.cpan.org/Ticket/Display.html?id=78590
         on_set_error   => 'die',
         max_key_length => min( ( eval { POSIX::PATH_MAX } || 260 ) - length( $root_dir->subdir('MetaCPAN', 0, 0)->absolute->stringify ) - 4 - 8, 248),
      )
   },
);

sub _mcpan_set_agent_str {
   my ($self, $ua) = @_;
   my $o = ucfirst($^O);
   
   my ($sysname, $nodename, $release, $version, $machine) = POSIX::uname;
   my $os = join('; ', "$sysname $release", $machine, $version);
   
   my $v = $self->VERSION || '';
   $ua->agent("Mozilla/5.0 ($o; $os) ".blessed($self)."/$v ".__PACKAGE__."/$VERSION ".$ua->_agent);

   return $ua;
}

42;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::MetaCPANInterfacer - something that will interact with MetaCPAN's API

=head1 SYNOPSIS

    # in your plugin/etc. code
    with 'Dist::Zilla::Role::MetaCPANInterfacer';
 
    my $obj = $self->mcpan->fetch(...);

=head1 DESCRIPTION

This role is simply gives you a L<MetaCPAN::API> object to use with caching, so
that other plugins can share that cache.  It uses the awesome example provided in
the L<MetaCPAN::API/SYNOPSIS>, contributed by Kent Fredric.

=head1 ATTRIBUTES

All of these attributes are f'ing lazy, because they like to sit around the house.
They are also read-write, as this is a role, and you might want to change around 
the defaults.

=head2 mcpan

=over

=item *

B<Type:> A L<MetaCPAN::API> object

=item *

B<Default:> A new object, using C<<< mcpan_ua >>> as the Tiny user agent

=back

=head2 mcpan_ua

=over

=item *

B<Type:> A L<HTTP::Tiny> compatible user agent

=item *

B<Default:> A new L<HTTP::Tiny::Mech> object, using C<<< mcpan_mechua >>> as the Mechanized user agent

=back

=head2 mcpan_mechua

=over

=item *

B<Type:> A L<WWW::Mechanize> compatible user agent

=item *

B<Default:> A new L<WWW::Mechanize::Cached::GZip> object, using C<<< mcpan_cache >>> as the cache attribute,
and some UA string changes.

=back

=head2 mcpan_cache

=over

=item *

B<Type:> A caching object

=item *

B<Default:> A new L<CHI> object, using the L<CHI::Driver::File|File> driver pointing to C<<< ~/.dzil/.webcache >>>

=back

=head1 TODO

The caching stuff could potentially be split, but frankly, none of the existing 
plugins really need caching all that much.  I've at least called the C<<< .webcache >>>
directory a generic name, so feel free to re-use it.

(Honestly, the only reason why this is a DZ module B<IS> the caching directory
name...)

=head1 SEE ALSO

L<Dist::Zilla::PluginBundle::Prereqs>, which uses this quite a bit.

=head1 AVAILABILITY

The project homepage is L<https://github.com/SineSwiper/Dist-Zilla-Role-MetaCPANInterfacer>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Dist::Zilla::Role::MetaCPANInterfacer/>.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Internet Relay Chat

You can get live help by using IRC ( Internet Relay Chat ). If you don't know what IRC is,
please read this excellent guide: L<http://en.wikipedia.org/wiki/Internet_Relay_Chat>. Please
be courteous and patient when talking to us, as we might be busy or sleeping! You can join
those networks/channels and get help:

=over 4

=item *

irc.perl.org

You can connect to the server at 'irc.perl.org' and talk to this person for help: SineSwiper.

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests via L<https://github.com/SineSwiper/Dist-Zilla-Role-MetaCPANInterfacer/issues>.

=head1 AUTHOR

Brendan Byrd <BBYRD@CPAN.org>

=head1 CONTRIBUTOR

Christian Walde <walde.christian@googlemail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Brendan Byrd.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
