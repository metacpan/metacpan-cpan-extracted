package Math::Giac;

use 5.006;
use strict;
use warnings;
use File::Temp;

=head1 NAME

Math::Giac - A perl interface to giac, a CAS(Computer Algebra System)

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';


=head1 SYNOPSIS

    use Math::Giac;

    my $giac;
    eval( {
       $giac=$Math::Giac->new;
    } );
    if ( $@ ){
        die("Failed to locate the giac binary");
    }

    my $results=$giac->run('sin(x)+cos(pi)-3');
    print $results."\n";

    $results=$giac->run('mathml(sin(x)+cos(pi)-3)');
    print $results."\n";

    $giac->set_vars({ A=>2 });
    my $results=$giac->run('sin(A)+cos(pi)-3');

=head1 METHODS

=head2 new

This initiates the object.

This also checks to make sure that giac is in the path. If
that check fails, it will die.

    my $giac;
    eval( {
       $giac=$Math::Giac->new;
    } );
    if ( $@ ){
        die("Failed to locate the giac binary");
    }

=cut

sub new {

	# make sure we can locate giac binary
	my $the_bin = `/bin/sh -c 'which giac 2> /dev/null'`;
	if ( $? != 0 ) {
		die("Can't locate the giac binary");
	}

	my $self = { vars => {}, };

	bless $self;

	return $self;
}

=head2 run

This returns the respected string after putting together a variable list.

The final output is what is returned, or $output[ $#output - 1 ], assuming it is
a single line one. Otherwise it works backwards to find a match.

This will remove the " from the start and return of the return, which gets added for
with latex or mathml.

This will die on a non-zero exit or no string being specified.

    my $results=$giac->run('sin(x)+cos(pi)-3');
    print $results."\n";

    $results=$giac->run('mathml(sin(x)+cos(pi)-3)');
    print $results."\n";

=cut

sub run {
	my $self   = $_[0];
	my $to_run = $_[1];

	if ( !defined($to_run) ) {
		die('No string specified to run');
	}

	$to_run =~ s/\n+$//;

	my @var_list   = keys( %{ $self->{vars} } );
	my $vars_addon = '';
	foreach my $cur_var (@var_list) {
		$vars_addon = $vars_addon . $cur_var . ':=' . $self->{vars}{$cur_var} . "\n";
	}

	$to_run = $vars_addon . $to_run;

	my $tmp = File::Temp->new;
	print $tmp $to_run;

	# run giac
	my $returned = `giac < $tmp 2> /dev/null`;
	if ( $? != 0 ) {
		die("giac exited with a non-zero... ".$?."... ".$@);
	}

	my @split_returned = split( /\n/, $returned );

	# if second to last is /^[0-9]+\>\>\ / thn return
	if ( $split_returned[ $#split_returned - 2 ] =~ /^[0-9]+\>\>\ / ) {
		# removes ", which get added for latex
		$split_returned[ $#split_returned - 1 ] =~ s/^\"//;
		$split_returned[ $#split_returned - 1 ] =~ s/\"$//;
		return $split_returned[ $#split_returned - 1 ];
	}

	# if we are here, go through it and put it toghether
	my $to_return = $split_returned[ $#split_returned - 1 ];
	my $line      = 3;
	my $loop      = 1;
	while ($loop) {
		$to_return = $split_returned[ $#split_returned - $line ] . "\n" . $to_return;

		# goto the previous line and check if it matches the end condition
		$line++;
		if ( $split_returned[ $#split_returned - $line ] =~ /^[0-9]+\>\>\ / ) {
			$loop = 0;
		}
	}

	# remove the "s that get added for multi line...
	$to_return =~ s/^\"//;
	$to_return =~ s/\"$//;

	return $to_return;
}

=head2 vars_clear

Removes any set variables.

As long as new was successfully called, this won't error.

    $giac->vars_clear;

=cut

sub vars_clear {
	my $self = $_[0];

	delete( $self->{vars} );

	$self->{vars} = {};

	return 1;
}

=head2 vars_set

Sets the variables.

xsThis requires one argument, which is a hash reference.

=cut

sub vars_set {
	my $self = $_[0];
	if ( ref( $_[1] ne 'HASH' ) ) {
		die('$_[1] is not a hash');
	}
	my $vars = $_[1];

	$self->{vars} = $vars;

	return 1;
}

=head1 VARIABLE HANDLING

Lets say the variable hash below is passed.

    {
        A=>1,
        B=>3,
    }

Then the resulting code will be as below.

    A:=1
    B:=3

Then requested item to run is then added to the end.
So if we are running 'sin(pi)+A' then we will have
the item below.

    A:=1
    B:=3
    sin(pi)+A

=head1 AUTHOR

Zane C. Bowers-HAdley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-math-giac at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Math-Giac>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Math::Giac


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Math-Giac>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Math-Giac>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Math-Giac>

=item * Search CPAN

L<https://metacpan.org/release/Math-Giac>

=item * Repository

L<https://gitea.eesdp.org/vvelox/Math-Giac>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by Zane C. Bowers-HAdley.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Math::Giac
