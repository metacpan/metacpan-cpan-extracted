#! perl

use strict;
use warnings;

use IPC::PrettyPipe::Stream::Utils 'parse_spec';

use Test::More;
use Test::Exception;


my @tests =
  (
 {
   op => '<',
   expect => { Op => '<', N => 0, type => 'redirect' }
 },

 { op => 'N<',
   expect => { Op => '<', type => 'redirect' },
 },

 { op => '>',
   expect => { Op => '>', N => 1, type => 'redirect'  }
 },

 { op => 'N>',
   expect => { Op => '>', type => 'redirect'  },
 },

 { op => '>>',
   expect => { Op => '>>', N => 1, type => 'redirect'  },
 },

 { op  => 'N>>',
   expect => { Op => '>>', type => 'redirect'  },
 },

 { op => '>&',
   expect => { Op => '>&', type => 'redirect_stdout_stderr'  },
 },

 { op => '&>',
   expect => { Op => '&>',  type => 'redirect_stdout_stderr' },
 },

 { op => 'M<&N',
   expect => { Op => '<&', type => 'dup' },
 },

 { op => 'N>&M',
   expect => { Op => '>&', type => 'dup' },
 },

 { op => 'N<&-',
   expect => { Op => '<&', M => '-', type => 'close' },
 },

 # { op => '<pty',
 #   expect => { Op => '<pty', N => 0 },
 # },

 # { op => 'N<pty',
 #   expect => { Op => '<pty' },
 # },

 # { op => '>pty',
 #   expect => { Op => '>pty', N => 1 },
 # },

 # { op => 'N>pty',
 #   expect => { Op => '>pty' },
 # },

 # { op => '<pipe',
 #   expect => { Op => '<pipe', N => 0 },
 # },

 # { op => 'N<pipe',
 #   expect => { Op => '<pipe' },
 # },

 # { op => '>pipe',
 #   expect => { Op => '>pipe', N => 1 },
 # },

 # { op => 'N>pipe',
 #   expect => { Op => '>pipe' },
 # },

);


sub test {

    my ( %par ) = @_;

    $par{desc} //= $par{op};

    lives_ok {
	    my $got = parse_spec( $par{op} );

	    delete $got->{param};

	    is_deeply( $got, $par{expect} );
    } $par{desc};

}

for my $test ( @tests ) {

	my @pt = ( $test );

	my @ftests;

	# fill in N & M
	my %r = ( N => [ 3, 45 ],
	          M => [ 6, 78 ]
	        );

	while ( @pt ) {

		my $t = shift @pt;

		if ( my ( $x ) = $t->{op} =~ /(N|M)/ ) {

			for my $r ( @{$r{$x}} ) {

				my %nt = %$t;
				$nt{expect} = { %{$nt{expect}} };
				$nt{op} =~ s/$x/$r/;
				$nt{expect}{$x} = $r;

				push @pt, \%nt;

			}

		}

		else {

			push @ftests, $t

		}

	}

	test( %$_ ) for @ftests;
}

# test if param checking works

lives_and {

	my $op = parse_spec( '2>&3' );

    is( $op->{Op}, '>&' );
	is( !!$op->{param}, !!0 );

} 'N>&M';

lives_and {

	my $op = parse_spec( '>' );

    is( $op->{Op}, '>' );
	is( $op->{param}, 1 );

} '>';

lives_and {

	my $op = parse_spec( '>&' );

    is( $op->{Op}, '>&' );
	is( $op->{param}, 1 );

} '>&';


done_testing;
