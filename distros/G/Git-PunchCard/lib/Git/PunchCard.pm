package Git::PunchCard;

use 5.006;
use strict;
use warnings;
use base 'Error::Helper';
use Cwd;

=head1 NAME

Git::PunchCard - Gathers info for making punchcard style graphs for git.

=head1 VERSION

Version 0.1.0

=cut

our $VERSION = '0.1.0';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Git::PunchCard;
    use Data::Dumper;
    use Text::Table;
    
    my $gpc = Git::PunchCard->new();
    
    $gpc->dir($some_git_repo_dir);
    if ( $gpc->error ){
        print "Could not process the directory.\n";
    }
    
    my $card=$gpc->get_card;
    
    print Dumper( $card );
    
    # The various keys for the hashes.
    my @days=('Sun','Mon','Tue','Wed','Thu','Fri','Sat', );
    my @hours=('00','01','02','03','04','05','06','07','08','09','10', '11','12','13','14','15','16','17','18','19','20','21','22','23');
    
    # Stores the lines to for the table.
    my @data;

    # Process each day hash in $card.
    foreach my $day ( @days ){
        my @line;
    
        # Add the day coloumn to the current line of the table.
        push( @line, $day );
    
        # Add each hour entry to the current line of the table.
        foreach my $hour ( @hours ){
            push( @line, $card->{$day}{$hour} );
        }
    
        # Finally add the total number of entries for that day.
        push( @line, $card->{$day}{total}.color('WHITE') );
    
        # add the new line to the table data
        push( @data, \@line );
    }
    
    # Init the Text::Table object and add our headers.
    my $table=Text::Table->new('','00','01','02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','19','20','21','22','23','Total');

    # Loads the data into the table
    $table->load( @data );
    
    # produce some useful? output
    print $table."\nTotal: ".$card->{total}."\n";

=head1 METHODS

=head2 new

Inits the object.

    my $gpc->new;

=cut

sub new {
	my $self={
			  perror=>undef,
			  error=>undef,
			  errorString=>'',
			  errorExtra=>{
						   flags=>{
								   1=>'gitError',
								   },
						   },
			  card=>{
					 total=>0,
					 max=>0,
					 average=>0,
					 min=>9999999999999999999999999999999999,
					 Sun=>{
						   total=>0,
						   max=>0,
						   average=>0,
						   min=>9999999999999999999999999999999999,
						   '00'=>0,
						   '01'=>0,
						   '02'=>0,
						   '03'=>0,
						   '04'=>0,
						   '05'=>0,
						   '06'=>0,
						   '07'=>0,
						   '08'=>0,
						   '09'=>0,
						   '10'=>0,
						   '11'=>0,
						   '12'=>0,
						   '13'=>0,
						   '14'=>0,
						   '15'=>0,
						   '16'=>0,
						   '17'=>0,
						   '18'=>0,
						   '19'=>0,
						   '20'=>0,
						   '21'=>0,
						   '22'=>0,
						   '23'=>0,
						   },
					 Mon=>{
						   total=>0,
						   max=>0,
						   average=>0,
						   min=>9999999999999999999999999999999999,
						   '00'=>0,
						   '01'=>0,
						   '02'=>0,
						   '03'=>0,
						   '04'=>0,
						   '05'=>0,
						   '06'=>0,
						   '07'=>0,
						   '08'=>0,
						   '09'=>0,
						   '10'=>0,
						   '11'=>0,
						   '12'=>0,
						   '13'=>0,
						   '14'=>0,
						   '15'=>0,
						   '16'=>0,
						   '17'=>0,
						   '18'=>0,
						   '19'=>0,
						   '20'=>0,
						   '21'=>0,
						   '22'=>0,
						   '23'=>0,
						   },
					 Tue=>{
						   total=>0,
						   max=>0,
						   average=>0,
						   min=>9999999999999999999999999999999999,
						   '00'=>0,
						   '01'=>0,
						   '02'=>0,
						   '03'=>0,
						   '04'=>0,
						   '05'=>0,
						   '06'=>0,
						   '07'=>0,
						   '08'=>0,
						   '09'=>0,
						   '10'=>0,
						   '11'=>0,
						   '12'=>0,
						   '13'=>0,
						   '14'=>0,
						   '15'=>0,
						   '16'=>0,
						   '17'=>0,
						   '18'=>0,
						   '19'=>0,
						   '20'=>0,
						   '21'=>0,
						   '22'=>0,
						   '23'=>0,
						   },
					 Wed=>{
						   total=>0,
						   max=>0,
						   average=>0,
						   min=>9999999999999999999999999999999999,
						   '00'=>0,
						   '01'=>0,
						   '02'=>0,
						   '03'=>0,
						   '04'=>0,
						   '05'=>0,
						   '06'=>0,
						   '07'=>0,
						   '08'=>0,
						   '09'=>0,
						   '10'=>0,
						   '11'=>0,
						   '12'=>0,
						   '13'=>0,
						   '14'=>0,
						   '15'=>0,
						   '16'=>0,
						   '17'=>0,
						   '18'=>0,
						   '19'=>0,
						   '20'=>0,
						   '21'=>0,
						   '22'=>0,
						   '23'=>0,
						   },
					 Thu=>{
						   total=>0,
						   max=>0,
						   average=>0,
						   min=>9999999999999999999999999999999999,
						   '00'=>0,
						   '01'=>0,
						   '02'=>0,
						   '03'=>0,
						   '04'=>0,
						   '05'=>0,
						   '06'=>0,
						   '07'=>0,
						   '08'=>0,
						   '09'=>0,
						   '10'=>0,
						   '11'=>0,
						   '12'=>0,
						   '13'=>0,
						   '14'=>0,
						   '15'=>0,
						   '16'=>0,
						   '17'=>0,
						   '18'=>0,
						   '19'=>0,
						   '20'=>0,
						   '21'=>0,
						   '22'=>0,
						   '23'=>0,
						   },
					 Fri=>{
						   total=>0,
						   max=>0,
						   average=>0,
						   min=>9999999999999999999999999999999999,
						   '00'=>0,
						   '01'=>0,
						   '02'=>0,
						   '03'=>0,
						   '04'=>0,
						   '05'=>0,
						   '06'=>0,
						   '07'=>0,
						   '08'=>0,
						   '09'=>0,
						   '10'=>0,
						   '11'=>0,
						   '12'=>0,
						   '13'=>0,
						   '14'=>0,
						   '15'=>0,
						   '16'=>0,
						   '17'=>0,
						   '18'=>0,
						   '19'=>0,
						   '20'=>0,
						   '21'=>0,
						   '22'=>0,
						   '23'=>0,
						   },
					 Sat=>{
						   total=>0,
						   max=>0,
						   average=>0,
						   min=>9999999999999999999999999999999999,
						   '00'=>0,
						   '01'=>0,
						   '02'=>0,
						   '03'=>0,
						   '04'=>0,
						   '05'=>0,
						   '06'=>0,
						   '07'=>0,
						   '08'=>0,
						   '09'=>0,
						   '10'=>0,
						   '11'=>0,
						   '12'=>0,
						   '13'=>0,
						   '14'=>0,
						   '15'=>0,
						   '16'=>0,
						   '17'=>0,
						   '18'=>0,
						   '19'=>0,
						   '20'=>0,
						   '21'=>0,
						   '22'=>0,
						   '23'=>0,
						   },
					 },
			  };
	bless $self;

	return $self;
}


=head2 card

One argument is taken and that is the directory to parse in.

If one is not passed, the current directory will be used.

IF this is called multiple times, each new instance will be added
to the current values.

    $gpc->dir( $dir )
    if ( $gpc->error ){
        print "Errored!\n";
    }

=cut

sub dir {
	my $self=$_[0];
	my $dir=$_[1];

	if( ! $self->errorblank ){
		return undef;
	}

	if (! defined( $dir ) ){
		$dir=getcwd;
	}

	chdir( $dir );

	my $output=`env LC_ALL=C git log --pretty=format:"%ad" --date=local --date=format:'%a %H'`;
	if ( $? != 0){
		$self->{error}=1;
		$self->{errorString}='"--pretty=format:\"%ad\" --date=local --date=format:\'%a %H\'" exited with a non-zero value';
		$self->warn;
	}

	my @lines=split(/\n/, $output);

	foreach my $line ( @lines ){
		my ($day, $hour)=split(/\ +/, $line);

		# Should never be undef, but just make sure.
		if (
			defined( $day ) &&
			defined( $hour )
			){
			# increment the one we hit on
			$self->{card}{$day}{$hour}++;
			$self->{card}{$day}{total}++;
			$self->{card}{total}++;

			if ( $self->{card}{$day}{$hour} > $self->{card}{max}){
				$self->{card}{max}=$self->{card}{$day}{$hour};
			}
			if ( $self->{card}{$day}{$hour} > $self->{card}{$day}{max}){
				$self->{card}{$day}{max}=$self->{card}{$day}{$hour};
			}
		}

		$self->{card}{$day}{average}= $self->{card}{$day}{total} / 24;
	}

	$self->{card}{average}= $self->{card}{total} / 168 ;

	foreach my $day ( 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat' ){
		for my $hour ( '00', '01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12', '13', '14', '15', '16', '17', '18', '19', '20', '21', '22', '23' ){
			if ( $self->{card}{$day}{$hour} < $self->{card}{$day}{min} ){
				$self->{card}{$day}{min}=$self->{card}{$day}{$hour};
			}
			if ( $self->{card}{$day}{$hour} < $self->{card}{min} ){
				$self->{card}{min}=$self->{card}{$day}{$hour};
			}
		}
	}

	
	return 1;
}

=head get_card

This returns the current card data.

The returned value is a hashref.

The first level keys are the three letter
day names the the second level keys are the
two digit hour.

There are two special keys 'total', 'max', min, and
avagerage.

'total' represents the total level of commits. So
at the primary level it is all the commits made to that
repo while and the secondary level it is all the comits
made to that repo on that day of the week.

'max' is the largest number of commits made. At the primary
level it is any hour on any day of the week while at the secondary
level it is the max made during any given hour that day.

'min' and 'average' is similar as max, but representing the min
and average instead.

For examples of making use of this, see the SYNOPSIS or check
out the script punchard-git.

    my $card=$gpc->get_card;

=cut

sub get_card{
	my $self=$_[0];
	my $dir=$_[1];

	if( ! $self->errorblank ){
		return undef;
	}

	return $self->{card};
}

=head1 ERROR NUMBERS/FLAGS

Error handling is provided by L<Error::Helper>.

=head2 1 / gitError

Git exited with a non-zero value.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-git-punchcard at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Git-PunchCard>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Git::PunchCard


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Git-PunchCard>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Git-PunchCard>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Git-PunchCard>

=item * Search CPAN

L<https://metacpan.org/release/Git-PunchCard>

=item * Primary Repo

L<https://gitea.eesdp.org/vvelox/Git-PunchCard/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2019 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Git::PunchCard
