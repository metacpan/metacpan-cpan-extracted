#!/usr/bin/perl -w

use strict;

use lib '../lib';

use Benchmark;
use Cwd;
use Fcntl qw( O_RDWR O_CREAT );
use Getopt::Long;
use MLDBM qw( DB_File Storable );
use Proc::ProcessTable;
use File::Path;
use File::Spec;

my %tests =
    ( print =>
      { code =>
        sub { call_comp( '/comps/print.mas', title => 'print', integer => 1000 ) },
        description =>
        'Calls $m->print many times.',
      },

      one_comp =>
      { code =>
        sub { call_comp( '/comps/comp.mas' ) },
        description =>
        'Calls a single component',
      },

      large =>
      { code =>
        sub { call_comp( '/comps/large.mas' ) },
        description =>
        'Calls a very large text-only component',
      },
    );

my %flags = 
    (
     test => {type  => ':s',
	      descr => 'Specify one or more tests to perform.',
	      default => []},
     profile =>
             {descr => '(Not implemented)'},
     reps => {type  => ':i',
	      descr => 'Number of times to repeat each test.  Defaults to 1000.',
	      default => 1000},
     save => {descr => 'Saves information to result_history.db (an MLDBM DB_File).'},
     cvs_tag =>
	     {type => ':s',
	      descr => 'A CVS tag (like "-r release-1-1-5") to check out in lib/ first.'},
     tag  => {type  => ':s',
	      descr => 'Specifies a tag to save to result_history.db.  '.
	               'Default is $HTML::Mason::VERSION or --cvs_tag value.'},
     clear_cache =>
	     {descr => 'Will clear on-disk cache first.  Useful for exercising the compiler.'},
     help => {descr => 'Prints this message and exits.'},
    );

my %opts;
$opts{$_} = $flags{$_}{default}
    foreach grep exists($flags{$_}{default}), keys %flags;

{
    local $^W;
    GetOptions( \%opts, map "$_$flags{$_}{type}", keys %flags );
}

if ( $opts{help} )
{
    usage();
    exit;
}

die "$0 must be run from inside the benchmarks/ directory\n"
  unless -e 'comps' and -d 'comps';

my $large_comp = File::Spec->catfile( 'comps', 'large.mas' );
# Don't check this into CVS because it's big:
unless ( -e $large_comp )
{
    open my $fh, ">$large_comp" or die "Can't create $large_comp: $!";
    print $fh 'x' x 79, "\n" for 1..30_000; # 80 * 30_000 = 2.4 MB
}

if ($opts{cvs_tag})
{
    my $cwd = cwd();
    my $lib = File::Spec->catdir( $cwd, '..', 'lib' );
    print "chdir $lib\n";
    chdir $lib or die "Can't chdir($lib): $!";
    my $cmd = "cvs update $opts{cvs_tag}";
    print "$cmd\n";
    open my($fh), "$cmd |" or die "Can't execute '$cmd': $!";
    print while <$fh>;
    close $fh or die "Can't close command: $!";
    
    $opts{tag} ||= $opts{cvs_tag};
    chdir $cwd or die "Can't chdir($lib): $!";
}

# Do this only after updating lib/ to proper CVS version
require HTML::Mason;

$opts{tag} ||= $HTML::Mason::VERSION;

# Clear out the mason-data directory, otherwise we might include
# compilation in one run and not the next
my $data_dir = File::Spec->rel2abs( File::Spec->catdir( cwd, 'mason-data' ) );
rmtree($data_dir) if $opts{clear_cache};

foreach my $test ( @{ $opts{test} } )
{
    unless ( exists $tests{$test} )
    {
        print "\n*** Invalid test: $test\n";
        usage();
        exit;
    }
}

my $interp =
    HTML::Mason::Interp->new( comp_root => File::Spec->rel2abs(cwd),
                              data_dir  => $data_dir,
                            );

my ($proc) = grep { $_->pid == $$ } @{ Proc::ProcessTable->new->table };

print "\n";
foreach my $name ( @{ $opts{test} } )
{
    my $results = Benchmark::timethis( $opts{reps}, $tests{$name}{code}, $name );

    my $per_sec = sprintf( '%.2f', $opts{reps} / ($results->[1] + $results->[2]) );

    my $rss  = sprintf( '%.2f', ( $proc->rss / 1024 ) );
    my $size = sprintf( '%.2f', ( $proc->size / 1024 ) );
#    my ($rss, $vsz) = `ps -eo rss,vsz -p $$` =~ /(\d+)\s+(\d+)/;
    print "   Real mem: $rss MB\n";
    print "Virtual mem: $size MB\n";

    if ( $opts{save} )
    {
        my %save;
        tie %save, 'MLDBM', 'result_history.db', O_CREAT | O_RDWR, 0644
            or die "Cannot tie to result_history.db: $!";

        my $tag = $opts{tag};
        my $old = $save{$tag};

        $old->{$name} ||= [];
        push @{ $old->{$name} }, $per_sec;

        $save{$tag} = $old;
    }
}
print "\n";

sub call_comp
{
    my ($comp, @args) = @_;

    my $out;
    $interp->out_method(\$out);
    $interp->exec( $comp, @args );
}

sub usage
{
    my $comps;
    foreach my $name ( sort keys %tests )
    {
        $comps .= sprintf( "            %-10s   %s\n", $name, $tests{$name}{description} );
    }

    my $opts;
    foreach my $name ( sort keys %flags )
    {
	$opts .= sprintf "  %13s  %s\n", "--$name", $flags{$name}{descr};
    }

    print <<"EOF";

Usage: $0 <options>

$opts
  Valid tests include:

$comps
EOF
}

