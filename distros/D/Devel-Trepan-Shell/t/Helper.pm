use warnings; use strict;
require Test::More;
use File::Spec;
use File::Basename;
use Data::Dumper;
my $debug = $^W;

package Helper;
use File::Basename qw(dirname); use File::Spec;
use English qw( -no_match_vars ) ;


# Runs debugger in subshell. 0 is returned if everything went okay.
# nonzero if something went wrong.
sub run_debugger($$$;$$)
{
    my ($test_invoke, $cmddir, $cmd_filename, $right_filename, $opts) = @_;
    my $full_cmd_filename = File::Spec->catfile(dirname(__FILE__), 
						'data', $cmd_filename);

    my $ext_file = sub {
        my ($ext) = @_;
        my $new_fn = $full_cmd_filename;
        $new_fn =~ s/\.cmd\z/.$ext/;
        return $new_fn;
    };

    my $run_opts = {
	basename  => 1,
	nx        => 1,
	highlight => 0,
	testing   => $full_cmd_filename,
	cmddir    => [$cmddir],
    };

    $right_filename = $ext_file->('right') unless defined($right_filename);
    $ENV{'TREPANPL_OPTS'} = Data::Dumper::Dumper($run_opts);
    my $cmd = "$EXECUTABLE_NAME -d:Trepan $test_invoke";
    Test::More::note( "running $cmd" );
    if ($debug) {
	print Data::Dumper::Dumper($run_opts), "\n"; 
	print $cmd, "\n"  if $debug;
    }
    my $output = `$cmd`;
    print "$output\n" if $debug;
    my $rc = $? >> 8;
    if ($opts->{do_test}) {
	Test::More::is($rc, 0, 'Debugger command executed successfully');
    }
    return $rc if $rc;
    open(RIGHT_FH, "<$right_filename");
    undef $INPUT_RECORD_SEPARATOR;
    my $right_string = <RIGHT_FH>;
    ($output, $right_string) = $opts->{filter}->($output, $right_string) 
	if $opts->{filter};
    my $got_filename;
    $got_filename = $ext_file->('got');
    # TODO : Perhaps make sure we optionally use eq_or_diff from 
    # Test::Differences here.
    my $equal_output = $right_string eq $output;
    Test::More::ok($right_string eq $output, 'Output comparison') 
	if $opts->{do_test};
    if ($equal_output) {
        unlink $got_filename;
	return 0;
    } else {
        open (GOT_FH, '>', $got_filename)
            or die "Cannot open '$got_filename' for writing - $OS_ERROR";
        print GOT_FH $output;
        close GOT_FH;
        Test::More::diag("Compare $got_filename with $right_filename:");
	my $output = `diff -u $right_filename $got_filename 2>&1`;
	my $rc = $? >> 8;
	# GNU diff returns 0 if files are equal, 1 if different and 2
	# if something went wrong. We also should take care of the
	# case where diff isn't installed. So although we expect a 1
	# for GNU diff, we'll also take accept 0, but any other return
	# code means some sort of failure.
	$output = `diff $right_filename $got_filename 2>&1` 
	     if ($rc > 1) || ($rc < 0) ;
        Test::More::diag($output);
	return 1;
    }
}

1;
