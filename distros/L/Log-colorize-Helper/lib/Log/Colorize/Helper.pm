package Log::Colorize::Helper;

use 5.006;
use strict;
use warnings;
use base 'Error::Helper';
use String::ShellQuote;

=head1 NAME

Log::Colorize::Helper - Makes searching and colorizing logs trivial with out all the need for piping

=head1 VERSION

Version 0.1.0

=cut

our $VERSION = '0.1.0';


=head1 SYNOPSIS

    use Log::Colorize::Helper;
    use Getopt::Std;
    
    #gets the options
    my %opts=();
    getopts('efhtn:g:ivlFGJ', \%opts);
    
    #init it
    my $clog=Log::Colorize::Helper->new;
    
    #set tail/head stuff if needed
    if ( ! defined( $opts{n} ) ){
    	$opts{n}=10;
    }
    if ( $opts{t} ){
    	$opts{t}=$opts{n};
    }
    if ( $opts{h} ){
    	$opts{h}=$opts{n};
    }
    
    $clog->colorize(
    	{
    		echo=>$opts{e},
    		log=>$ARGV[0],
    		head=>$opts{h},
    		tail=>$opts{t},
    		grep=>$opts{g},
    		less=>$opts{l},
    		follow=>$opts{f},
    		'grep-insensitive'=>$opts{i},
    		'grep-invert'=>$opts{v},
    		'grep-first'=>$opts{F},
    		bzip2=>$opts{J},
    		gzip=>$opts{G},
    	}
    	);

This module uses L<Error::Helper> for error reporting.

=head1 METHODS

=head2 new

Creates a new object. This method will never error.

    my $clog=Log::Colorize::Helper->new;

=cut

sub new {
	my $self={
		perror=>undef,
		error=>undef,
		errorString=>'',
		errorExtra=>{
			flags=>{
				1=>'noFileSpecified',
				2=>'doesNotExist',
				3=>'badCombo',
				4=>'noGre[',
			},
		},
	};
	bless $self;
	return $self;
}

=head2 colorize

=head3 args hash

=head4 bzip2

The log is compressed using bzip2.

=head4 echo

Print the command used.

=head4 follow

A Perl boolean for if it should follow while tailing.

Default is false.

If set to true and tail is not specified it is set to 10.

=head4 head

How many lines to print at the top of the file.

The default is 0, false. This means head will not be used.

Can't be combined with tail.

=head4 grep

An optional string to grep for.

=head4 grep-first

A Perl boolean to run grep infront of the head/tail instead of after.

The default is false.

=head4 grep-insensitive

This is a Perl boolean value for if grep should be case insensitive.

The default is false.

=head4 grep-invert

This is a Perl boolean value for if grep should be inverted or not.

The default is false.

=head4 gzip

The log is compressed using gzip.

=head4 less

A Perl boolean value for if it should pass it to 'less -R'

=head4 log

The log file to colorize.

=head4 tail

How many lines to print at the bottom of the file.

The default is 0, false. This means tail will not be used.

Can't be combined with head.

    #gets the options
    my %opts=();
    getopts('efhtn:g:ivlFGJ', \%opts);
    
    #init it
    my $clog=Log::Colorize::Helper->new;
    
    #set tail/head stuff if needed
    if ( ! defined( $opts{n} ) ){
    	$opts{n}=10;
    }
    if ( $opts{t} ){
    	$opts{t}=$opts{n};
    }
    if ( $opts{h} ){
    	$opts{h}=$opts{n};
    }
    
    $clog->colorize(
    	{
    		echo=>$opts{e},
    		log=>$ARGV[0],
    		head=>$opts{h},
    		tail=>$opts{t},
    		grep=>$opts{g},
    		less=>$opts{l},
    		follow=>$opts{f},
    		'grep-insensitive'=>$opts{i},
    		'grep-invert'=>$opts{v},
    		'grep-first'=>$opts{F},
    		bzip2=>$opts{J},
    		gzip=>$opts{G},
    	}
    	);


=cut

sub colorize{
	my $self=$_[0];
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	}

	$self->errorblank;

	#set various defaults
	if ( !defined( $args{head} ) ){
		$args{head}=0;
	}
	if ( !defined( $args{echo} ) ){
		$args{echo}=0;
	}
	if ( !defined( $args{tail} ) ){
		$args{tail}=0;
	}
	if ( !defined( $args{less} ) ){
		$args{less}=0;
	}
	if ( !defined( $args{bzip2} ) ){
		$args{bzip2}=0;
	}
	if ( !defined( $args{gzip} ) ){
		$args{gzip}=0;
	}
	if ( !defined( $args{'grep-first'} ) ){
		$args{'grep-first'}=0;
	}
	if ( !defined( $args{'grep-insensitive'} ) ){
		$args{'grep-insensitive'}=0;
	}
	if ( !defined( $args{'grep-invert'} ) ){
		$args{'grep-invert'}=0;
	}

	#set tail to 10 if it is not set and follow is set
	if ( $args{follow} && ! $args{tail} ){
		$args{tail}=10;
	}

	#error if grep is not set and follow is true
	if ( $args{'grep-first'} && ! defined( $args{grep} ) ){
		$self->{error}=4;
		$self->{errorString}='grep-first is true, but grep is not set';
		$self->warn;
		return undef;
	}
	
	#cam't combine these both tail and head
	if ( $args{head} & $args{tail} ){
		$self->{error}=3;
		$self->{errorString}="Can't combine head and tail";
		$self->warn;
		return undef;
	}

	#can't combine follow and head
	if ( $args{head} && $args{follow} ){
		$self->{error}=3;
		$self->{errorString}="Can't combine head and follow";
		$self->warn;
		return undef;
	}

	#can't combine follow and head
	if ( $args{'grep-first'} && $args{follow} ){
		$self->{error}=3;
		$self->{errorString}="Can't combine follow and grep first";
		$self->warn;
		return undef;
	}
	
	#make sure we have a log specified
	if ( !defined( $args{log} ) ){
		$self->{error}=1;
		$self->{errorString}='no log file specified';
		$self->warn;
		return undef;
	};

	#make sure it exists and is a file
	if ( ! -f $args{log} ){
		$self->{error}=2;
		$self->{errorString}='"'.$args{log}.'" is not a file or does not exist';
		$self->warn;
		return undef;
	}

	#the command to use, initial assembly
	my $command='cat '.shell_quote( $args{log} ).' ';

	#unarchive if needed...
	if ( $args{bzip2} ){
		$command=$command.'| bunzip2 ';
	}
	if ( $args{gzip} ){
		$command=$command.'| gunzip ';
	}
	
	#puts grep together
	my $grep='';
	if ( defined( $args{grep} ) ){
		$grep='| grep';

		if ( $args{'grep-insensitive'} ){
			$grep=$grep.' -i';
		}
		if ( $args{'grep-insensitive'} ){
			$grep=$grep.' -v';
		}

		#unarchive if needed
		if ( $args{'grep-first'} && $args{bzip2} ){
			$grep=$grep.' -J';
		}
		if ( $args{'grep-first'} && $args{gzip} ){
			$grep=$grep.' -Z';
		}
		
		$grep=$grep.' '.$args{grep};
	}

	#apply grep if it is first
	if ( $args{'grep-first'} ){
		$command=$grep.' '.shell_quote( $args{log} ).' ';
		$grep=''; #blank grep so when we apply it we are not running it twice
	}

	#add head if needed
	if ( $args{head} ){
		$command=$command.'| head -n '.$args{head}.' ';
	}

	#tail if needed
	if ( $args{tail} ){
		if ( $args{follow} ){
			$command='tail -f -F -n '.$args{tail}.' '.shell_quote( $args{log} ).' ';
		}else{
			$command=$command.'| tail -n '.$args{tail};
		}
	}

	#add grep and colorize
	$command=$command.$grep.' | colorize';

	#add less if desired
	if ( $args{less} ){
		$command=$command.' | less -R';
	}

	#echo if needed
	if ( $args{echo} ){
		print $command."\n";
	}
	
	system($command);
	
	return 1;
}

=head1 ERROR CODES

=head2 1/noFileSpecified

No log file specified.

=head2 2/doesNotExist

The log file does not exist.

=head2 3/badCombo

A bad combination of options.

=head2 4/noGrep

grep-first is true, but there is no grep.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-log-colorize-helper at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Log-Colorize-Helper>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Log::Colorize::Helper


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Log-Colorize-Helper>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Log-Colorize-Helper>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Log-Colorize-Helper>

=item * Search CPAN

L<http://search.cpan.org/dist/Log-Colorize-Helper/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2017 Zane C. Bowers-Hadley.

This program is distributed under the (Simplified) BSD License:
L<http://www.opensource.org/licenses/BSD-2-Clause>

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

* Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Log::Colorize::Helper
