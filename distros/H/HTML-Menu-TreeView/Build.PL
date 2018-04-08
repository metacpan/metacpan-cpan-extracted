use strict;
use Module::Build;
use vars qw($skip);

my $class = Module::Build->subclass(class => "Module::Build::Custom",code  => <<'SUBCLASS' );
    use File::Copy;
    use File::Path;
    my $release = 'blib/rhtml/';
    my $dir     = 'httpdocs/';
    my $path    = '.';

    sub ACTION_build {
        my $self = shift;
        $path = $self->{properties}{htd};
        &change($dir);
        $self->SUPER::ACTION_build;
        &replacePath('blib/lib/HTML/Menu/TreeView.pm');

    }

    sub change {
        my $d = shift;
        chomp($d);
        opendir( IN, $d ) or die "Install failed: $d $!:$/";
        my @files = readdir(IN);
        closedir(IN);
        for( my $i = 0 ; $i <= $#files ; $i++ ) {
            unless ( $files[$i] =~ /^\./ ) {
                my $c = "$d/$files[$i]";
                my $e = $c;
                $e =~ s/^$dir(.*)/$1/;
                unless ( -d $c ) {
                    copy( $c, "$release/$e" ) or die "copy failed: $! $/ $c  $/ $release/$e";
                } else {
                    mkpath("$release/$e") unless ( -d "$release/$e" );
                    &change("$d/$files[$i]") unless $files[$i] =~ /^\./;
                }
            }
        }
    }

    sub replacePath{
        my $f = shift;
        chmod 0644, $f;
        open( EDIT, "+<$f" ) or die "replacePath $f $! $/";
        my $file = '';
        while(<EDIT>) {
            s/%PATH%/$path/;
            $file .= $_;
        }
        seek( EDIT, 0, 0 );
        print EDIT $file;
        truncate( EDIT, tell(EDIT) );
        close(EDIT);
    }
	
	sub replace{
		my $replace = shift;
		my $with    = shift;
		my $f       = shift;
		chmod 0644, $f;
		open(EDIT, "+<$f") or die "$! $f  $/";
		my $files = '';
		while (<EDIT>)
		{
			$_ =~ s/$replace/$with/g;
			$files .= $_;
		}
		seek(EDIT, 0, 0);
		print EDIT $files;
		truncate ( EDIT, tell( EDIT ) );
		close( EDIT );
		chmod 0755, $f if ($f =~ /^.*.pl$/);
	}

    sub ACTION_install_examples {
        my $self = shift;
        my $prefix = defined $inctance->{phash}{runtime_params}{disk}{prefix} ? $inctance->{phash}{runtime_params}{disk}{prefix} . '/' : '';
        $release = "$prefix$self->{properties}{cgi}";
        use Cwd;
        my $cwd = cwd;
        my $dir = $cwd . '/examples';
        opendir( DIR, $dir ) or die $!;
        my @files = grep {/.*.p(l|m)$/} readdir(DIR);
        closedir(DIR);

        for( my $i = 0 ; $i <= $#files ; $i++ ) {
            my $c = "$dir/$files[$i]";
            copy( $c, "$release/$files[$i]" ) or die $!;
			&replace('#!/usr/bin/perl', '#!perl', "$release/$files[$i]") if $^O eq 'MSWin32';
            chmod 0755, "$release/$files[$i]";
        }
        $dir .= '/html';
        opendir( DIR, $dir ) or die $!;
        @files = readdir(DIR);
        closedir(DIR);
        $release = "$prefix$self->{properties}{htd}";
        for( my $i = 0 ; $i <= $#files ; $i++ ) {
            unless ( $files[$i] =~ /^\./ ) {
                my $c = "$dir/$files[$i]";
                copy( $c, "$release/$files[$i]" ) or die $!;
            }
        }
    }
SUBCLASS
my $inctance = $class->new(
    get_options => {
                    skip => {store => \$skip},
                   },
    module_name => 'HTML::Menu::TreeView',
    requires    => {
                 'Test::More'    => '>=0.7',
                 'perl'          => '5.006000',
                },
    ($] >= 5.005 ? (AUTHOR => 'Dirk Lindner <dirk.lze@gmail.com>') : ()),
    dist_abstract      => 'Create a HTML TreeView from scratch',
    license            => 'lgpl',
    create_makefile_pl => 'passthrough',
    meta_merge => { 
    resources => {
        repository => 'https://sourceforge.net/p/lindnerei/ajax/HEAD/tree/HTML-Menu-TreeView'
    }
    },
      sign =>1,
);
$inctance->{properties}{htd} = "/var/www/htdocs";
eval 'use HTML::Menu::TreeView qw(documentRoot)';
$inctance->{properties}{htd} = documentRoot() unless $@;
$inctance->{properties}{htd} = $inctance->args('htd') if defined $inctance->args('htd');
$inctance->{properties}{cgi} = '/var/www/cgi-bin';
$inctance->{properties}{cgi} = $inctance->args('cgi') if defined $inctance->args('cgi');

unless ($skip) {
    $inctance->{properties}{htd} =
      Module::Build->prompt("Where is your Document root ?", $inctance->{properties}{htd});
    $inctance->{properties}{cgi} =
      Module::Build->prompt("Where is your cgi-bin Directory ?", $inctance->{properties}{cgi});
} else {
    print "Document root: $inctance->{properties}{htd}$/";
    print "cgi-bin Directory : $inctance->{properties}{cgi}$/";
}
$inctance->{properties}{install_path}{lib}   = $inctance->{properties}{cgi} . '/lib/';
$inctance->{properties}{install_path}{rhtml} = $inctance->{properties}{htd};
$inctance->create_build_script;
