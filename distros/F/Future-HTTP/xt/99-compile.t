#!perl
use warnings;
use strict;
use File::Find;
use Test::More;
BEGIN {
    eval 'use Capture::Tiny ":all"; 1';
    if ($@) {
        plan skip_all => "Capture::Tiny needed for testing";
        exit 0;
    };
};

plan 'no_plan';

require './Makefile.PL';
# Loaded from Makefile.PL
our %module = get_module_info();

my $last_version = undef;

sub check {
    #return if (! m{(\.pm|\.pl) \z}xmsi);

    my ($stdout, $stderr, $exit) = capture(sub {
        system( $^X, '-Mblib', '-c', $_ );
    });

    s!\s*\z!!
        for ($stdout, $stderr);

    if( $exit ) {
        diag $stderr;
        diag "Exit code: ", $exit;
        fail($_);
    } elsif( $stderr ne "$_ syntax OK") {
        diag $stderr;
        fail($_);
    } else {
        pass($_);
    };
}

my %skip = (
    'lib/Future/HTTP/AnyEvent.pm' => 1,
    'lib/Future/HTTP/Mojo.pm' => 1,
    'lib/Future/HTTP/NetAsync.pm' => 1,
    'lib/Future/HTTP/Tiny/Paranoid.pm' => 1,
    'blib/lib/Future/HTTP/AnyEvent.pm' => 1,
    'blib/lib/Future/HTTP/Mojo.pm' => 1,
    'blib/lib/Future/HTTP/NetAsync.pm' => 1,
    'blib/lib/Future/HTTP/Tiny/Paranoid.pm' => 1,
);

if(( $ENV{USER} || '') eq 'corion' and (`hostname`||'') eq 'outerlimits') {
    %skip = ();
}

my @files;
find({wanted => \&wanted, no_chdir => 1},
    grep { -d $_ }
         'blib/lib', 'examples', 'lib'
    );

if( my $exe = $module{EXE_FILES}) {
    push @files, @$exe;
};

for (grep {!$skip{$_}} @files) {
    check($_)
}

sub wanted {
  push @files, $File::Find::name if /\.p(l|m|od)$/;
}
