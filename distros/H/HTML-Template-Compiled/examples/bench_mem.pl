#!/usr/bin/perl
use strict;
use warnings;
$|=1;
use File::Copy;
use FindBin qw/ $RealBin /;
chdir "$RealBin/..";
# call perl examples/bench_mem.pl htc 1000
my ($mod, $count) = @ARGV;
usage() unless $mod;
mkdir "examples/mem";
mkdir "examples/memcache";
mkdir "examples/memcache/htc";
mkdir "examples/memcache/jit";
my %modules = (
	tt => 'Template',
	ht => 'HTML::Template',
	htc => 'HTML::Template::Compiled',
	htj => 'HTML::Template::JIT',
);
$count ||= 5;
eval "require $modules{$mod}";
#print HTML::Template::Compiled->VERSION,$/;
my %files = (
	ht => 'test.htc',
	htc => 'test.htc',
	htj => 'test.htc',
	tt => 'test.tt',
);
my @unique = keys %{ {reverse %files} };

sub new_htc {
	my $t = HTML::Template::Compiled->new(
		path => 'examples/mem',
		loop_context_vars => 1,
		filename => $_[0],
		cache_dir => "examples/memcache/htc",
		#cache => 0,
	);
	return $t;
}
sub new_ht {
	my $t = HTML::Template->new(
		path => 'examples/mem',
		loop_context_vars => 1,
		filename => $_[0],
		cache => 1,
	);
	return $t;
}
sub new_htj {
	my $t = HTML::Template::JIT->new(
		path => ['examples/mem'],
		loop_context_vars => 1,
		filename => $_[0],
		cache => 1,
		jit_path => 'examples/memcache/jit',
	);
	return $t;
}
my $tt;
if ($mod eq 'tt') {
	$tt = Template->new(
		COMPILE_EXT => '.ttc',
		COMPILE_DIR => 'examples/memcache/tt',
		INCLUDE_PATH => 'examples/mem',
	);
}
sub new_tt { return $tt }
my %params = (
name => '',
loopa => [{a=>3},{a=>4},{a=>5}],
#a => [qw(b c d)],
loopb => [{ inner => 23 }],
c => [
{
d=>[({F=>11},{F=>22}, {F=>33})]
},
{
d=>[({F=>44}, {F=>55}, {F=>66})]
}
],
if2 => 1,
if3 => 0,
blubber => "html <test>",
);
open OUT, ">>/dev/null";
#open OUT, ">&STDOUT";
my $cparam = $count;

my $ht_out = sub {
	my $t = shift;
	return unless defined $t;
	$params{name} = (ref $t).' '.$cparam++;
	$t->param(%params);
	my $out = $t->output;
	$t->param({});
	print OUT $out;
};
my $outputs = {
	ht => $ht_out,
	htc => $ht_out,
	htj => $ht_out,
	tt => sub {
		my ($t,$f) = @_;
		return unless defined $t;
		#print OUT "TT $f\n";
		$t->process($f, \%params, \*OUT);
	},
};
my $news = {
	tt => \&new_tt,
	ht => \&new_ht,
	htc => \&new_htc,
	htj => \&new_htj,
};
{
	my $file = $files{$mod};
	print "File $file\n";
	-f "examples/mem/included.tt" or
	copy "examples/included.tt", "examples/mem/included.tt" or die $!;
	-f "examples/mem/included.htc" or
	copy "examples/included.htc", "examples/mem/included.htc" or die $!;
    # preprocess half of the templates
    my $t = process($count/2, $mod, $file);
    print_top("root");
    for my $i (1..2) {
        if (my $pid = fork) {
        }
        else {
            print "Starting loop $i\n";
            my $t = process($count, $mod, $file);
            print_top($i);
            print "End loop $i\n";
            exit;
        }
    }
    print "Waiting for child processes to finish\n";
    wait;
    print "Still waiting for child processes to finish\n";
    wait;
    print "Finished child processes\n";
    print_top("root");
	#<STDIN>;
}

sub print_top {
	my $top = qx{top -b -n 1 |grep $$};
    #my $top = qx{top -b -n 1 |grep perl};
	chomp $top;
	print "\ntop($_[0]) PID $$:\n$top\n";
}
sub process {
    my ($count, $mod, $file) = @_;
    for my $i ( 1 .. $count ) {
        my $dup = sprintf "%s.%02d", $file, $i;
        -f "examples/mem/$dup"
          or copy "examples/$file", "examples/mem/$dup"
          or die $!;
        my $t;
        if ($mod eq 'tt') {
            $t = $tt;
        }
        else {
            $t = $news->{$mod}->("$dup") or die $!;
        }
        #print STDERR "$mod '$t' loop '$i'\r";
        $outputs->{$mod}->( $t, $dup ) or die $t->error;
        #select undef, undef, undef, 1/($count/5);
    }
}

sub usage {
    print <<"EOM";
Usage: $0 (tt|ht|htc) num
Example: 100 iterations for TT:
  $0 tt 100
EOM
    exit;
}

__END__
-- with caching the template objects extra

:!perl examples/bench_mem.pl htj 500
File test.htc
htj 'tmpl_3588d6c4e3fc6254d1133a51e4c439b0' loop '500'
top:   744 tina      25   0 18980  16m  10m S  0.0  3.3   0:07.74 perl

:!perl examples/bench_mem.pl ht 500
File test.htc
ht 'HTML::Template=HASH(0x89ae50c)' loop '500'
top:   754 tina      25   0 11928  10m 2648 S  0.0  2.0   0:02.61 perl

:!perl examples/bench_mem.pl tt 500
File test.tt
tt 'Template=HASH(0xa184104)' loop '500'
top:   759 tina      24   0 36556  34m 2668 S  0.0  6.7   0:03.15 perl

:!perl examples/bench_mem.pl htc 500
File test.htc
htc 'HTML::Template::Compiled=ARRAY(0x94a0f44)' loop '500'
top:   764 tina      25   0 23272  21m 2732 S  0.0  4.2   0:01.54 perl

-- without caching the template objects extra

:!perl examples/bench_mem.pl htj 500
File test.htc
htj 'tmpl_3588d6c4e3fc6254d1133a51e4c439b0' loop '500'
top:   784 tina      25   0 18964  16m  10m S  0.0  3.3   0:07.76 perl

:!perl examples/bench_mem.pl ht 500
File test.htc
ht 'HTML::Template=HASH(0x88b62dc)' loop '500'
top:   792 tina      25   0 10900 9312 2648 S  0.0  1.8   0:02.66 perl

:!perl examples/bench_mem.pl tt 500
File test.tt
tt 'Template=HASH(0x8366640)' loop '500'
top:   797 tina      25   0  5744 4084 2668 S  0.0  0.8   0:03.62 perl

:!perl examples/bench_mem.pl htc 500
File test.htc
htc 'HTML::Template::Compiled=ARRAY(0x9498650)' loop '500'
top:   788 tina      25   0 23256  21m 2732 S  0.0  4.2   0:01.55 perl


