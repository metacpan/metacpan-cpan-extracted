package MDV::Distribconf;

# $Id: Distribconf.pm 232708 2007-12-30 04:28:14Z nanardon $

our $VERSION = '3.14';

=head1 NAME

MDV::Distribconf - Read and write config of a Mandriva Linux distribution tree

=head1 SYNOPSIS

    use MDV::Distribconf;

    my $d = MDV::Distribconf->new("/path/to/the/distribution/root");
    $d->load()
	or die "This doesn't seem to be a distribution tree\n";

    print $d->getpath(undef, "root") ."\n";
    foreach ($d->listmedia) {
        printf "%s -> %s\n", $d->getpath($_, "hdlist"), $d->getpath($_, path);
    }

=head1 DESCRIPTION

MDV::Distribconf is a module to get or write the configuration of a Mandriva
Linux distribution tree. This configuration is stored in a file called
F<media.cfg>, aimed at replacing the old-style F<hdlists> file.

The format of the F<hdlists> file is limited and doesn't allow to add new
values without breaking compatibility, while F<media.cfg> is designed for
extensibility. To keep compatibility with old tools, this module is able
to generate an F<hdlists> file based on F<media.cfg>.

This module is able to manage both configuration of old-style trees
(F<Mandrake/base/> for OS versions 10.0 and older) and of new-style ones
(F<media/media_info/> for 10.1 and newer).

=head1 media.cfg

The F<media.cfg> is structured like a classical F<.ini> file. All
parameters are optional; this means that a readable empty file is ok, if
this is what you want :)

F<media.cfg> contains sections, each section corresponding to a media,
except the C<[media_info]> section wich is used to store global info. The
section name is the (relative) path where the rpms are located. It is
sufficient to uniquely identify a media.

Some values have specific signification:

=over 4

=item media specific values:

=over 4

=item B<hdlist>

The path or basename of the hdlist. By default, this is
C<hdlist_mediapath.cz>, with slashes and spaces being replaced by '_'.

=item B<synthesis>

The path or basename of the synthesis. By default, this is the hdlist
name prefixed by C<synthesis>.

=item B<pubkey>

The path or basename of the gpg public key file. By default, this is
the media name prefixed by C<pubkey_>.

=item B<name>

A human-readable name for the media. By default this is the media path
(that is, the section name), where slashes have been replaced by
underscores.

=back

=item global specific values:

=over 4

=item B<version>

OS version.

=item B<branch>

OS branch (cooker, etc.)

=item B<arch>

Media target architecture.

=item B<root>

The root path of the distribution tree. This value is not set in
F<media.cfg>, can't be owerwritten, and is only used internally.

=item B<mediadir>

The default path relative to the 'root' path where media are
located. MDV::Distribconf is supposed to configure this automatically
to C<Mandrake> or to C<media>, depending on the OS version.

=item B<infodir>

The default path relative to the 'root' path where distrib metadata
are located. MDV::Distribconf is supposed to configure this automatically
to C<Mandrake/base> or to C<media/media_info>, depending on the OS
version.

=back

=back

For the paths of the hdlist and synthesis files, if only a basename is
provided, the path is assumed to be relative to the mediadir or infodir.
(hdlist and synthesis are created in both directories.) If it's a complete
path, it's assumed to be relative to the 'root'. For example,

    hdlist.cz    -> <root>/<infodir>/hdlist.cz
    ./hdlist.cz  -> <root>/./hdlist.cz

Here's a complete example of a F<media.cfg> file:

    # Comment
    [media_info]
    # some tools can use those values
    version=2006.0
    branch=cooker

    [main]
    hdlist=hdlist_main.cz
    name=Main

    [../SRPMS/main]
    hdlist=hdlist_main.src.cz
    name=Main Sources
    noauto=1

    [contrib]
    hdlist=hdlist_contrib.cz
    name=Contrib

    [../SRPMS/contrib]
    hdlist=hdlist_contrib.src.cz
    name=Contrib Sources
    noauto=1

=head1 METHODS

=cut

use strict;
use warnings;
use Config::IniFiles;

sub mymediacfg_version {
    $VERSION =~ /^(\d+)\./;
    $1
}

=head2 MDV::Distribconf->new($root)

Returns a new MDV::Distribconf object, C<$root> being the top level
directory of the tree.

=cut

sub new {
    my ($class, $path, $mediacfg_version) = @_;
    my $distrib = {
	root => $path,
	infodir => '',
	mediadir => '',
    type => '', # mdk vs mdv
    mediainfodir => '',
	cfg => new Config::IniFiles(-default => 'media_info', -allowcontinue => 1),
    };

    if (!defined($mediacfg_version)) {
        $distrib->{cfg}->newval('media_info', 'mediacfg_version', mymediacfg_version());
    }

    bless($distrib, $class)
}

=head2 $distrib->load()

Finds and loads the configuration of the distrib: locate the path where
information is found; if available loads F<media.cfg>, if available loads
F<hdlists>.

Returns 1 on success, 0 error (that is, if no directory containing media
information is found, or if no F<media.cfg>, neither F<hdlists> files are
found).

See also L<loadtree>, L<parse_hdlists> and L<parse_mediacfg>.

=cut

sub load {
    my ($distrib) = @_;
    $distrib->loadtree() or return 0;
    $distrib->parse_mediacfg() || $distrib->parse_hdlists() or return 0;
    return 1;
}

=head2 $distrib->loadtree()

Tries to find a valid media information directory, and set infodir and
mediadir. Returns 1 on success, 0 if no media information directory was
found.

=cut

sub loadtree {
    my ($distrib) = @_;

    if (-d "$distrib->{root}/media/media_info") {
        $distrib->{infodir} = 'media/media_info';
        $distrib->{mediadir} = 'media';
        $distrib->{mediainfodir} = '/media_info';
        $distrib->{type} = 'mandriva';
    } elsif (-d "$distrib->{root}/Mandrake/base") {
        $distrib->{infodir} = 'Mandrake/base';
        $distrib->{mediadir} = 'Mandrake';
        $distrib->{mediainfodir} = '';
        $distrib->{type} = 'mandrake';
    } else {
        return 0;
    }
    return 1;
}

=head2 check_mediacfg_version($wanted_version)

Check that the current distrib uses this version or lesser, which means it is
supported.

=cut

sub check_mediacfg_version {
    my ($distrib, $wanted_version) = @_;

    # Check wanted version is <= than the module
    # Otherwise the module can't properly handle it
    return 0 if (mymediacfg_version() < $wanted_version);

    return 0 if ($wanted_version < $distrib->getvalue(undef, 'mediacfg_version'));

    return 1
}

=head2 $distrib->settree($spec)

Virtual set the internal structure of the distrib.

$spec can be 'mandrake' or 'mandriva' to automatically load a know structure
(old and new fascion, or a hashref:

  mediadir => 'media',
  infodir => 'media/media_info',

=cut

sub settree {
    my ($distrib, $spec) = @_;

    if (ref($spec) eq 'HASH') {
        foreach (qw(infodir mediadir mediainfodir)) {
            $distrib->{$_} = $spec->{$_} || '';
        }
    } elsif ($spec && $spec =~ /mandrake/i) {
        $distrib->{infodir} = 'Mandrake/base';
        $distrib->{mediadir} = 'Mandrake';
        $distrib->{type} = 'mandrake';
        $distrib->{mediainfodir} = '';
    } else { # finally it can be everything, we do not care
        $distrib->{infodir} = 'media/media_info';
        $distrib->{mediadir} = 'media';
        $distrib->{mediainfodir} = '/media_info';
        $distrib->{type} = 'mandriva';
    }
}


=head2 $distrib->parse_hdlists($hdlists)

Reads the F<hdlists> file whose path is given by the parameter $hdlist,
or, if no parameter is specified, the F<hdlists> file found in the media
information directory of the distribution. Returns 1 on success, 0 if no
F<hdlists> can be found or parsed.

=cut

sub parse_hdlists {
    my ($distrib, $hdlists) = @_;
    $hdlists ||= "$distrib->{root}/$distrib->{infodir}/hdlists";

    open my $h_hdlists, "<", $hdlists
	or return 0;
    $distrib->{cfg} = new Config::IniFiles( -default => 'media_info', -allowcontinue => 1);
    my $i = 0;
    foreach (<$h_hdlists>) {
        s/#.*//; s/^\s*//;
        chomp;
        length or next;
        my ($options, %media);
        ($options, @media{qw(hdlist path name size)}) = /^\s*(?:(.*):)?(\S+)\s+(\S+)\s+([^(]*)(?:\s+\((\w+)\))?$/;
        if (!$media{hdlist}) { # Hack because hdlists format really sucks
            ($options, @media{qw(hdlist path name size)}) = /^\s*(?:(.*):)?(\S+)\s+(\S+)\s+(.*)$/;
        }
        if ($options) {
            $media{$_} = 1 foreach split /:/, $options;
        }
        $media{name} =~ s/\s*$//;
        $media{path} =~ s!^$distrib->{mediadir}/+!!;
        foreach (qw(hdlist name size), $options ? split(/:/, $options) : ()) {
            $distrib->{cfg}->newval($media{path}, $_, $media{$_})
		or die "Can't set value [$_]\n";
        }
    }
    close($h_hdlists);

    return 1;
}

=head2 $distrib->parse_version($fversion)

Reads the F<VERSION> file whose path is given by the parameter $fversion,
or, if no parameter is specified, the F<VERSION> file found in the media
information directory of the distribution. Returns 1 on success, 0 if no
F<VERSION> can be found or parsed.

=cut

sub parse_version {
    my ($distrib, $fversion) = @_;
    $fversion ||= $distrib->getfullpath(undef, 'VERSION');
    open my $h_ver, "<", $fversion
	or return 0;
    my $l = <$h_ver>;
    close $h_ver;
    chomp $l;
    # XXX heuristics ahead. This breaks regularly.
    my ($version, $branch, $product, $arch) = $l =~ /^(?:mandrake|mandriva) ?linux\s+(\w+)\s+([^- ]*)-([^- ]*)-([^- ]*)/i;
    $distrib->{cfg}->newval('media_info', 'version', $version);
    $distrib->{cfg}->newval('media_info', 'branch', $branch);
    $distrib->{cfg}->newval('media_info', 'product', $product);
    $distrib->{cfg}->newval('media_info', 'arch', $arch);
    return 1;
}

=head2 $distrib->parse_mediacfg($mediacfg)

Reads the F<media.cfg> file whose path is given by the parameter
$mediacfg, or, if no parameter is specified, the F<media.cfg> file found
in the media information directory of the distribution. Returns 1 on
success, 0 if no F<media.cfg> can be found or parsed.

=cut

sub parse_mediacfg {
    my ($distrib, $mediacfg) = @_;
    $mediacfg ||= "$distrib->{root}/$distrib->{infodir}/media.cfg";
    (-f $mediacfg && -r _) &&
        ($distrib->{cfg} = new Config::IniFiles( -file => $mediacfg, -default => 'media_info', -allowcontinue => 1))
            or return 0;

    return $distrib->check_mediacfg_version(mymediacfg_version());
}

=head2 $distrib->listmedia()

Returns an array of existing media in the configuration

=cut

sub listmedia {
    my ($distrib) = @_;
    return grep { $_ ne 'media_info' } $distrib->{cfg}->Sections;
}

=head2  $distrib->mediaexists($media)

Return true if $media exists

=cut

sub mediaexists {
    my ($distrib, $media) = @_;
    $media ||= 'media_info';
    return ($media eq 'media_info' || $distrib->{cfg}->SectionExists($media));
}

sub _expand {
    my ($self, $media, $value, $level) = @_;
    $value or return $value; # being lazy
    # unsupported if < 3
    $self->getvalue(undef, 'mediacfg_version') < 3 and return $value;
    $media ||= 'media_info';
    $level ||= 0; # avoid infinite loop
    ++$level >= 15 and return $value;

    $value =~ s@\%{(\w+)}@
        $self->getvalue($media, $1) || '%{' . $1 . '}';
    @eg;
    $value =~ s@\${(\w+)}@
        $self->getvalue('media_info', $1, $level) || '${' . $1 . '}';
    @eg;

    $value
}

=head2 $distrib->getvalue($media, $var)

Returns the $var value for $media, or C<undef> if the value is not set.

If $var is "name", "hdlist" or "synthesis", and if the value is not explicitly
defined, the return value is expanded from $media.

If $media is "media_info" or C<undef>, you'll get the global value.

This function doesn't cares about path, see L<getpath> for that.

=cut

sub getvalue {
    my ($distrib, $media, $var, $level) = @_;
    $media ||= 'media_info';

    $distrib->mediaexists($media) or return;

    my $default = "";
    for ($var) {
        /^synthesis$/		and $default = 'synthesis.' . lc($distrib->getvalue($media, 'hdlist', $level));
        /^hdlist$/		and $default = 'hdlist_' . lc($distrib->getvalue($media, 'name', $level)) . '.cz';
        /^pubkey$/		and $default = 'pubkey_' . lc($distrib->getvalue($media, 'name', $level));
        /^(pubkey|hdlist|synthesis)$/ and do {
            $default =~ s![/ ]+!_!g;
        };
        /^name$/		and do { 
            $default = $media;
            $default =~ s![/ ]+!_!g;
            last;
        };
        /^productid$/   and do {
            return join(',', map { "$_=" . ($distrib->getvalue(undef, $_) || '') }
                qw(vendor distribution type version branch release arch product));
        };
        /^path$/		and return $media;
        /^root$/		and return $distrib->{root};
        /^mediacfg_version$/	and 
            return $distrib->{cfg}->val('media_info', 'mediacfg_version') || 1;
        /^VERSION$/		and do { $default = 'VERSION'; last };
        /^product.id$/	and do { $default = 'product.id'; last };
        /^product$/		and do { $default = 'Download'; last };
        /^(MD5SUM|depslist.ordered|compss|provides)$/      
                        and do { $default = $_; last };
        /^(?:tag|branch)$/	and do { $default = ''; last };
        /^(?:media|info)dir$/	and do { $default = $distrib->{$var}; last };
        /^os$/ and do { $default = 'linux'; last; };
        /^gnu$/ and do { $default = 1; last; };
        /^vendor$/ and do { $default = $distrib->{type}; last; };
        /^arch$/ and do { $default = undef;  last; };
        /^platform$/ and do {
            my $arch = $distrib->getvalue($media, 'arch');
            $default = defined($arch) ? sprintf('%s-%s-%s%s',
                $arch,
                $distrib->getvalue($media, 'vendor'),
                $distrib->getvalue($media, 'os'),
                $distrib->getvalue($media, 'gnu') ? '-gnu' : '',
                ) : undef;
            last;
        };
        /^rpmsrate$/ and do { $default = 'rpmsrate'; last; };
        /^description$/ and do { $default = 'description'; last; };
        /^provide$/ and do { $default = 'description'; last; };
        /^depslist.ordered$/ and do { $default = 'description'; last; };
    }
    return $distrib->_expand($media, $distrib->{cfg}->val($media, $var, $default), $level);
}

=head2 $distrib->getpath($media, $var)

Gives relative path of $var from the root of the distrib. This function is
useful to know where files are actually located. It takes care of location
of media, location of index files, and paths set in the configuration.

=cut

sub getpath {
    my ($distrib, $media, $var) = @_;
    $distrib->mediaexists($media) or return;
    $var ||= ""; # Avoid undef value
    my $val = $distrib->getvalue($media, $var);
    $var =~ /^(?:root|VERSION|product\.id|(?:media|info)dir)$/ and return $val;
    my $thispath = $var eq 'path' ? $distrib->{mediadir} : $distrib->{infodir};
    if ($distrib->getvalue(undef, 'mediacfg_version') >= 2) {
        return $thispath . '/' . $val;
    } else {
        return ($val =~ m!/! ? "" :
            ($var eq 'path' ? $distrib->{mediadir} : $distrib->{infodir} )
        . "/") . $val;
    }
}

=head2 $distrib->getmediapath($media, $var)

This function does the same than getpath except it return the path proper
to the media for files having doble location (index for example).

=cut


sub getmediapath {
    my ($distrib, $media, $var) = @_;
    my %files = (
        pubkey => 'pubkey',
        hdlist => 'hdlist.cz',
        synthesis => 'synthesis.hdlist.cz',
        MD5SUM => 'MD5SUM',
        infodir => '',
    );
    $var eq 'path' and return $distrib->getpath($media, 'path');
    return $distrib->getpath($media, 'path') . $distrib->{mediainfodir} . "/$files{$var}";
}

=head2 $distrib->getfullpath($media, $var)

Does the same thing than getpath(), but the return value will be
prefixed by the 'root' path. This is a shortcut for:

    $distrib->getpath(undef, 'root') . '/' . $distrib->getpath($media, $var).

=cut

sub getfullpath {
    my $distrib = shift;
    my $path = $distrib->getpath(@_) or return;
    return $distrib->getpath(undef, 'root') if (($_[1] || '') eq 'root');
    return $distrib->getpath(undef, 'root') . '/' . $path;
}

=head2 $distrib->getfullmediapath($media, $var)

This function does the same than getpath except it return the path proper
to the media for files having doble location (index for example).

=cut

sub getfullmediapath {
    my $distrib = shift;
    my $path = $distrib->getmediapath(@_) or return;
    return $distrib->getpath(undef, 'root') . '/' . $path;
}

=head2 $distrib->getdpath($media, $var)

Does the same thing than getpath(), but the return always return the best for
file having twice location (index).

You may want to use this function to ensure you allways the good value.

=cut

sub getdpath {
    my ($distrib, $media, $var) = @_;

    if ($var =~ /^(hdlist|synthesis|pubkey|MD5SUM)$/) {
        if ($distrib->{type} eq 'mandriva') {
            return $distrib->getmediapath($media, $var);
        } else {
            return $distrib->getpath($media, $var);
        }
    } else {
        return $distrib->getpath($media, $var);
    }
}

=head2 $distrib->getfulldpath($media, $var)

Does the same thing than getfullpath(), but the return always return the best
for file having twice location (index).

You may want to use this function to ensure you allways the good value.

=cut

sub getfulldpath {
    my $distrib = shift;
    my $path = $distrib->getdpath(@_) or return;
    return $distrib->getpath(undef, 'root') . '/' . $path;
}


1;

__END__

=head1 SEE ALSO

gendistrib(1)
L<MDV::Distribconf::Build>
L<MDV::Distribconf::MediaCFG>
L<MDV::Distribconf::Checks>

=head1 AUTHOR

The code has been written by Olivier Thauvin <nanardon@mandriva.org> and is
currently maintained by Rafael Garcia-Suarez <rgarciasuarez@mandriva.com>.
Thanks to Sylvie Terjan <erinmargault@mandriva.org> for the spell checking.

=head1 LICENSE AND COPYRIGHT

(c) 2005, 2006, 2007 Olivier Thauvin
(c) 2005, 2006, 2007 Mandriva

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2, or (at your option)
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

=cut
