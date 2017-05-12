# \\puma\perl\bin\perl.exe "-MExtUtils::Command::MM" "-e" "test_harness(1, 'blib\lib', 'blib\arch')" t\tidy_commandline.t

# To do:
#  test with multiple input files

package AtExit;

sub new {
	my ($package, $callfunc) = @_;
	die "AtExit->new requires a subroutine ref argument" unless ref $callfunc eq 'CODE';
	my $self = $callfunc;
	bless $self, $package;
}

sub DESTROY {
	my $self = shift;
	&{$self};
}

#############################################################

package main;

BEGIN {
    local @INC=('./t', @INC);
    require TestUtils;
    import TestUtils qw( create_tidy_test compare_indentation escape );
}

use Test::More qw/no_plan/;
use File::Temp qw/tempfile/;
use strict;
use warnings;

BEGIN {
    use_ok('Hardware::Vhdl::Tidy');
}

sub test_tidy_commandline;

test_tidy_commandline ({
	test_description => 'tidy_commandline with no switches', 
	switches => [],
	vhdl =>
"--process
process
begin
    wait on foo;
#if SIMULATING==1
    t <= al-foo*5;
#else
    t <= al-foo;
#endif
    q <= t + bar * x;
end
  process
  ;
-- etc",
});

for my $switches ( [qw( -ipp )], [qw( --indent-preprocessor )] ) {
test_tidy_commandline ({
	test_description => 'tidy_commandline with switches '.join(' ', @$switches), 
	switches => $switches,
	vhdl =>
"--process
process
begin
    wait on foo;
    #if SIMULATING==1
    t <= al-foo*5;
    #else
    t <= al-foo;
    #endif
    q <= t + bar * x;
end
  process
  ;
-- etc",
});
}

for my $switches ( [qw( -sil 1 )], [qw( --starting-indentation-level 1 )] ) {
test_tidy_commandline ({
	test_description => 'tidy_commandline with switches '.join(' ', @$switches), 
	switches => $switches,
	vhdl =>
"    --process
    process
    begin
        wait on foo;
        t <= al-foo*5;
        q <= t + bar * x;
    end
      process
      ;
    -- etc",
});
}

for my $switches ( [qw( -i 3 --ci 1 )], [qw( --indentation 3 --continuation-indentation 1 )] ) {
test_tidy_commandline ({
	test_description => 'tidy_commandline with switches '.join(' ', @$switches), 
	switches => $switches,
	vhdl =>
"--process
process
begin
   wait on foo;
   t <= al
    -foo*5;
   for x in 1 to 5 loop
      q <= t
       + bar
       * x;
   end loop;
end
 process
 ;
-- etc",
});
}

for my $switches ( [qw( -i 3 --ci 0 )], [qw( --indentation 3 --continuation-indentation 0 )] ) {
test_tidy_commandline ({
	test_description => 'tidy_commandline with switches '.join(' ', @$switches), 
	switches => $switches,
	vhdl =>
"--process
process
begin
   wait on foo;
   t <= al
   -foo*5;
   q <= t + bar * x;
end
process
;
-- etc",
});
}

for my $switches ( [qw( -i 3 --ci 1 -t 4 )], [qw( --indentation 3 --continuation-indentation 1 --tab_spaces 4 )] ) {
test_tidy_commandline ({
	test_description => 'tidy_commandline with switches '.join(' ', @$switches), 
	switches => $switches,
	vhdl =>
"--process
process
begin
   wait on foo;
   t <= al
\t-foo*5;
   for x in 1 to 5 loop
\t  q <= t
\t   + bar
\t   * x;
   end loop;
end
 process
 ;
-- etc",
});
}

for my $switches ( [qw( -i 3 --ci 1 -t 2 )], [qw( --indentation 3 --continuation-indentation 1 --tab_spaces 2 )] ) {
test_tidy_commandline ({
	test_description => 'tidy_commandline with switches '.join(' ', @$switches), 
	switches => $switches,
	vhdl =>
"--process
process
begin
\t wait on foo;
\t t <= al
\t\t-foo*5;
\t for x in 1 to 5 loop
\t\t\tq <= t
\t\t\t + bar
\t\t\t * x;
\t end loop;
end
 process
 ;
-- etc",
});
}

for my $switches ( [qw( -ppp @ )], [qw( --preprocessor-prefix @ )] ) {
test_tidy_commandline ({
	test_description => 'tidy_commandline with switches '.join(' ', @$switches), 
	switches => $switches,
	vhdl =>
'--process
process
begin
    wait on foo;
@if SIMULATING==1
    t <= al-foo*5;
@else
    t <= al-foo;
@endif
    q <= t + bar * x;
end
  process
  ;
-- etc',
});
}

for my $switches ( [qw( -b )] ) {
test_tidy_commandline ({
	test_description => 'tidy_commandline with switches '.join(' ', @$switches), 
	switches => $switches,
    inplace => 1,
    ext => '.bak',
	vhdl =>
"--process
process
begin
    wait on foo;
#if SIMULATING==1
    t <= al-foo*5;
#else
    t <= al-foo;
#endif
    q <= t + bar * x;
end
  process
  ;
-- etc",
});
}

for my $switches ( [qw( -b -bext backup )] ) {
test_tidy_commandline ({
	test_description => 'tidy_commandline with switches '.join(' ', @$switches), 
	switches => $switches,
    inplace => 1,
    ext => 'backup',
	vhdl =>
"--process
process
begin
    wait on foo;
#if SIMULATING==1
    t <= al-foo*5;
#else
    t <= al-foo;
#endif
    q <= t + bar * x;
end
  process
  ;
-- etc",
});
}

sub slurp {
    my $fh = shift;
    local $/;
    return <$fh>;
}

sub test_tidy_commandline {
	my $args = shift;
	my $infile = 'test_in.vhd';

	my ($correct_tidy_ref, $untidy_ref) = create_tidy_test($args->{vhdl});

	# write $vhdl_in to a file
	{
		my $fh;
		open $fh, '>', $infile || die $!;
        binmode $fh;
		print $fh @{$untidy_ref};
		close $fh;
	}

	# open new temp. for output
	my $fho = tempfile;
    #open $fho, '+>', 'test_out.vhd' || die $!;
    binmode $fho;
	{
		local @ARGV = (@{$args->{switches}}, $infile);
        open my $oldout, '>&STDOUT' or die "Can't dup STDOUT: $!";
		my $restore_old_fh = AtExit->new( sub { open STDOUT, ">&", $oldout or die "Can't dup \$oldout: $!"; } );
        open STDOUT, '>&', $fho or die "Can't redirect STDOUT: $!";
        select STDOUT; $| = 1;      # make unbuffered
		Hardware::Vhdl::Tidy::parse_commandline();
        $restore_old_fh = undef;
	}
    if ($args->{inplace}) {
        seek $fho, 0, 2; # go to the end of the output file so that we can find out how much output there was
        is(tell $fho, 0, $args->{test_description}.': nothing written to STDOUT');
        $fho = undef;
        
        open $fho, '<', $infile. $args->{ext} || die $!;
        binmode $fho;
        my $input_backup = [readline $fho];
        ok(compare_indentation($untidy_ref, $input_backup), $args->{test_description}.': backup file');
        $fho = undef;

        open $fho, '<', $infile || die $!;
        binmode $fho;
    }
    else {
        seek $fho, 0, 0; # go to the start of the output file so that we can read it all
    }
	my $tidy_output = [readline $fho];
	close $fho;
	ok(compare_indentation($correct_tidy_ref, $tidy_output), $args->{test_description});
}
