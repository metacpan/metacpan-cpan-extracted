#!./perl

use strict;
use Config;
use vars qw(%How $Old);
BEGIN {
    warn " >>> set_defaults.PL running...\n";
    require "./DefaultConf.pm";
    my $pk;
 CONF: {
	eval { require "./Conf.pm" };
	if (!$@) {
	    warn " >>> using ./Conf.pm\n";
	    $pk = 'Envy::Conf';
	    last CONF;
	}

	my $sitelib = $Config{sitelib};
	my $prefix = $ENV{PERL5PREFIX} || $Config{prefix};
	$sitelib =~ s/$Config{prefix}/$prefix/;
	local @INC = ($sitelib);
	eval { require Envy::Conf };
	if (!$@) {
	    $pk = 'Envy::Conf';
	    warn " >>> using installed Envy::Conf ($INC{'Envy/Conf.pm'})\n";
	    last CONF;
	}

	$pk = 'Envy::DefaultConf';
	warn " >>> using DefaultConf.pm\n";
    };
    no strict 'refs';
    if (grep /How/, @{"$pk\::EXPORT_OK"}) {
	$pk->import('%How');
    } else {
	$pk->import(qw(%env0 $startup $prefix @path));
	$Old=1;
    }
    require "./subst.pm";
    require "./VERSION";
}
use File::Compare;
use Symbol;

eval q[%How = (env0=>\%env0, startup=>$startup, prefix=>$prefix, path=>\@path)]
    if $Old;
for my $k (keys %Envy::DefaultConf::How) {
    $How{$k} = $Envy::DefaultConf::How{$k} if !defined $How{$k};
}

sub do_init_env {
    my ($file) = @_;
    my $env0 = $How{env0};
    my $str='';
    if ($file eq 'login.IN') {
	for my $k (sort keys %$env0) {
	    my $v=$$env0{$k};
	    $str .= "setenv $k $v\n";
	}
    } else {
	for my $k (sort keys %$env0) {
	    my $v=$$env0{$k};
	    $str .= "$k=$v; export $k\n";
	}
    }
    $str;
}

# This maps symlinks from $ETOP/etc/login/ to $HOME/.
my $symlink = {
	       'dot.profile' => ['.profile', '.zprofile', '.bash_profile'],
	       'dot.shrc' => ['.shrc', '.zshrc', '.bashrc'],
	       'dot.login' => ['.login'],
	       'dot.cshrc' => ['.cshrc'],
	       'dot.dtprofile' => ['.dtprofile'],
	      };

my $symlink_str;
while (my($k,$v) = each %$symlink) {
    for my $to (@$v) {
	$symlink_str .= 'safe_symlink $ETOP/etc/login/'.$k.' $HOME/'.$to."\n";
    }
}

my $perl5lib = $Config{sitelib};
$perl5lib =~ s/$Config{prefix}/$How{prefix}/;

my $subst = {
	     '#ENVY.PL#' => "$How{prefix}/bin/envy.pl",
	     '#ETOP#' => $How{prefix},
	     '#FORCEPATH#' => "qw(".join(' ',split /:+/,$How{env0}{PATH}).")",
	     '#INITIAL_ENV#' => \&do_init_env,
	     '#PERL5LIB#' => $perl5lib,
	     '#SAFE_SYMLINK#' => $symlink_str,
	     '#SEARCH#' => "qw(".join(' ',@{$How{path}}).")",
	     '#SHSEARCH#' => join(':',@{$How{path}}),
	     '#STARTUP#' => $How{startup},
	     '#STRICTNESS#' => $How{strictness},
	     '#VERSION#' => $VERSION,
	    };

sub go {
    my $status = gensym;
    open $status, ">Conf.pm.new" or die "open >Conf.pm.new: $!";
    select $status;
    my $env0 = $How{env0};
    print q[# Re-generate by uncommenting the following line:
# return 0;

use strict;
package Envy::Conf;
require Exporter;
use vars qw(@ISA @EXPORT_OK
	    %How %env0 $startup $strictness $prefix @path);
@ISA = ('Exporter');
@EXPORT_OK = qw(%How);

# Prefix (such that $prefix/bin/envy.pl exists)
$prefix = ]."'$How{prefix}';".q[

# Hardcoded environment
%env0 = (
].join('',map { "\t'$_' => '$$env0{$_}',\n" } sort keys %$env0) .q[);

# the directory containing the First dimension
@path = qw(
].join('', map { "\t$_\n" } @{$How{path}}).q[);

# the .env file containing the First dimension
$startup = ]."'$How{startup}';".q[

# Strictness (0 is normal; 1 upgrades warnings to errors)
$strictness = ].$How{strictness}.q[;

# ------------------------------------------------------------------------
# All done; now collect all settings into an easy to use hash:
#
%How = (env0=>\%env0, startup=>$startup, prefix=>$prefix, path=>\@path,
	strictness=>$strictness);

1;
];
    close $status;

    my $f1 = gensym;
    my $f2 = gensym;
    for my $in (keys %$subst_files) {
	my $out = $subst_files->{$in};
	my $gen = "\n";
	$gen .= "# set_defaults.PL $in -> $out\n";
	warn "Substituting $in -> $out\n";
	my $v2str = sub {
	    my $v = shift;
	    if (ref $v) { $v->($in) }
	    else { $v }
	};
	open($f1, $in) or die "open $in: $!";
	open($f2, ">$out") or die "open $out: $!";
	while (defined(my $l=<$f1>)) {
	    while (my($k,$v)=each %$subst) {
		$l =~ s/$k/&$v2str($v)/e;
	    }
	    print $f2 $l;
	}
	print $f2 $gen;
	close $f1;
	close $f2;
	chmod(0755, $out)==1 or die "chmod $out: $!";
    }
}
&go;

if (compare("./Conf.pm", "./Conf.pm.new") != 0) {
    rename "./Conf.pm.new", "./Conf.pm";
    warn " >>> Done!  New configuration written to ./Conf.pm <<<\n";
} else {
    warn " >>> Done!  (./Conf.pm unchanged) <<<\n";
    unlink "./Conf.pm.new";
}
