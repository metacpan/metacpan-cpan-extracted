package Getopt::CommandLineExports;

use 5.006;
use strict;
use warnings;
use CGI;


=head1 NAME

Getopt::CommandLineExports - Allow suroutines within a script to export comand line options with bash auto completion

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';


=head1 SYNOPSIS

Example Code:

    use strict;
    use warnings;
    use Getopt::CommandLineExports qw(&regAC &parseArgsByPosition &parseArgs
        &checkArgs $scriptName @exportedSubs %cmdLines);

    $scriptName = qq[TestCommandLineExports];
    %cmdLines = (
        twoScalars          => [qw/ ONE=s TWO=s /],
        oneHash         => [qw/ ONE=s% /],
        oneList         => [qw/ ONE=s@ /],
    );
    sub twoScalars
    {
        my %h = (
            ONE => undef,
            TWO => undef,
            ( parseArgs \@_, @{$cmdLines{twoScalars}}),
        );
        print "twoScalars missing required argument:\n"
            . join( "\n", checkArgs \%h ) . "\n"
            if ( checkArgs \%h );
        return " $h{ONE} , $h{TWO} \n";
    }

    sub oneHash
    {
        my %h = (
            ONE => undef,
            ( parseArgs \@_, @{$cmdLines{oneHash}}),
        );
        print "oneHash missing required argument:\n"
            . join( "\n", checkArgs \%h ) . "\n"
            if ( checkArgs \%h );
        print "oneHash\n";
        print join("\n", (%{$h{ONE}}));
    }

    sub oneList
    {
        my %h = (
            ONE => undef,
            ( parseArgs \@_, @{$cmdLines{oneList}}),
        );
        print "oneList missing required argument:\n"
            . join( "\n", checkArgs \%h ) . "\n"
            if ( checkArgs \%h );
        print "oneList\n";
        print join("\n",@{$h{ONE}});
    }

    # The "Main" subroutine. Not included in package, must be added manually to a script

    if ( defined $ARGV[0] )
    {
        if ( defined( &{ $ARGV[0] } ) )
        {
            no strict 'refs';
            my $subRef = shift @ARGV;
            print join( "\n", &$subRef(@ARGV) ) . "\n" unless $subRef =~ /regAC/ ;
            &$subRef($scriptName, \@exportedSubs, \%cmdLines) if $subRef =~ /regAC/ ;
            exit 0;
        }
    }

    # some unit test examples:
    twoScalars "Hello1", "Hello2";
    twoScalars {ONE => "Hello1", TWO => "Hello2"};
    twoScalars "--ONE Hello1 --TWO Hello2";
    twoScalars "--ONE", "Hello1", "--TWO", "Hello2";
    twoScalars "--ONE", "Hello1", "--TWO", "Hello2", "--THREE", "Hello3"; # complains about "unknown option: three"

=head1 PURPOSE

This module is intended to provide the capability to have a single
script export many subcommands in a consistant manner.

In the example above, the script is named "TestCommandLineExports".
On a bash style command line, the following commands would work:

    TestCommandLineExports twoScalars --ONE "Arg1" --TWO "Arg2"

and would print:

    Arg1, Arg2

while 

    TestCommandLineExports twoScalars --TWO "Arg2"
    
would print:

    twoScalars missing required argument:
    --ONE

TestCommandLineExports twoScalars may also be called through a CGI interface as well.

The principle use of this was to provide an easy, consistant, method
to provide unit test ability for scripts.  It also allows for a single
script to export multiple subcommands and, with the included bash
auto completion function, allows for the subcommands and options to
integrate nicely with the bash shell.


=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS


=head2 regAC

Print a bash auto completion script.
Returns a script roughly sutiable for the bash_autocompletion functions:

Include roughly the following in your script:

    # this hash uses perl's Getopt::Long format 
    my %cmdLines = (
        regAC => [qw//],
        SubCommandOne => [qw/DIRECTORY=s YES_OR_NO=s ANY_FILE=s/],
        SubCommandTwo => {qw/INT=i/],
    )
    my @exportedSubs = keys %cmdLines;

    #you can use bash completion words here ("__directory__") to complete with directories
    # The default is filename completion
    my %additionalWordCompletions = (
        SubCommandOne => {
            DIRECTORY => [qw/__directory__/],
            YES_OR_NO => [qw/yes no/],
        },
    );

    if ( defined $ARGV[0] )
    {
        if ( defined( &{ $ARGV[0] } ) )
        {
            no strict 'refs';
            my $subRef = shift @ARGV;
            print join( "\n", &$subRef(@ARGV) ) . "\n" unless $subRef =~ /regAC/ ;
            &$subRef($scriptName, \@exportedSubs, \%cmdLines, \%additionalWordCompletions) if $subRef =~ /regAC/ ;
            exit 0;
        }
    }


Run from the commandline as:

    ScriptName regAC > /etc/bash_completion.d/ScriptName
    source /etc/bash_completion.d/ScriptName

or 

    sudo ScriptName regAC
    source /etc/bash_completion.d/ScriptName

and the script should be registered with all the commands in:

    @Getopt::CommandLineExports::exportedSubs

and the command lines from:

    %Getopt::CommandLineExports::cmdLines

=head2 parseArgs

parse and argument list according to a command line spec in the Getopt::Long format.
Returns a hash of arguments and values.

    %cmdLines = (
        function   => [qw/ REQUIRED_ARGUMENT=s OPTIONAL_ARGUMENT_ONE=s OPTIONAL_ARGUMENT_TWO=s  /],
    );

    my %h = (
        REQUIRED_ARGUMENT     => undef, # undef means the argument is required
        OPTIONAL_ARGUMENT_TWO => 'default value',  # a default value is provided
        # no mention of OPTIONAL_ARGUMENT_ONE means that it could be provided or could be undefined
        # checkArgs below will NOT include this in the missing argument list
        (   parseArgs \@_, @{$cmdLines{function}})
    );

=head2 parseArgsByPosition

parse an argument list according to a command line spec in the Getopt::Long format.

        parseArgsByPosition( \@argv, \%args, @ComSpec);

The first argument is the standard argv list.
The second is a reference to a hash to receive the arguments parsed from argv 
(a reference is passed to allow for default values to be set.
The last argument is a reference to the argument spec in Getopt::Long format

as an example:

    my %args = (ARG1 => "Default Value", ARG2 => undef);

    parseArgsByPosition( ["One", "Two", "Three"], \%args, qw/ARG1=s ARG2=s ARG3=s ARG4=s/);

should set %args to be (ARG1 => "One", ARG2 => "Two", ARG3 => "Three")

=head2 checkArgs

checkArgs will return a list of arguments that are undefined.  This can be used
to identify required arguments with:

    my %h = (
        REQUIRED_ARGUMENT     => undef,
        (   parseArgs \@_, @{$cmdLines{function}})
    );
    print "function missing required argument:\n"
        . join( "\n", checkArgs \%h ) . "\n"
        if ( checkArgs \%h );

=cut



BEGIN {
    use Exporter ();
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
# set the version for version checking
    $VERSION = 0.04;
    @ISA = qw(Exporter);
    @EXPORT_OK = qw(&regAC &parseArgsByPosition &parseArgs &checkArgs);
    %EXPORT_TAGS = ( ALL => [ qw(&regAC &parseArgsByPosition &parseArgs &checkArgs) ], ); 

#your exported package globals go here,
#as well as any optionally exported functions
}


# exported package globals go here



use Getopt::Long qw(GetOptionsFromString GetOptionsFromArray);
use warnings;
sub regAC
{
    my $scriptName = shift;
    my $esRef = shift;
    my $cmdRef = shift;
    my $addWordsRef = shift;
    my @exportedSubs = @{$esRef};
    my %cmdLines = %{$cmdRef};
    my %addWords = %{$addWordsRef} if defined $addWordsRef;
    my $cmdOptsText = "";
	my $cmdoptMoreWordsText = "";
    while (my ($cmdName, $params) =each %cmdLines)
    {
        $cmdOptsText .= "$cmdName => [qw/" . join(" ",@$params) . "/],\n";
    }
    while (my ($cmdName, $options) =each %addWords)
    {
		$cmdoptMoreWordsText .= "$cmdName => {\n";
		while (my ($option, $params) =each %$options)
		{
			$cmdoptMoreWordsText .= "$option => [qw/" . join(" ",@$params) . "/],\n";
		}
		$cmdoptMoreWordsText .= "},\n";		
	}
	my $bashFunc = <<EOF
_$scriptName()
EOF
;	
	$bashFunc .= <<'EOF'
{
    local cur prev cmds cmdOpts perlCmd
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    subcmd="${COMP_WORDS[1]}" 
    cmds="
EOF
;
    chomp($bashFunc);
    $bashFunc = $bashFunc . join (" ", @exportedSubs);
    $bashFunc = $bashFunc . '"' ."\n";
    $bashFunc = $bashFunc . <<EOF
    if [[ \$COMP_CWORD -eq 1 ]] ; then
        COMPREPLY=( \$(compgen -W "\${cmds}" -- \${cur}) )
        return 0
    fi
    perlCmd=\$(cat <<CMDLINE
%cmdopt = (
EOF
;
    $bashFunc = $bashFunc . $cmdOptsText;
    $bashFunc = $bashFunc . <<'EOF'  

);
\$noArgs = 1;
\$optionalArgs = 0;
\$cmd = \$ARGV[0];
\$arg = \$ARGV[1];
\$doAddWords = 1 if defined \$ARGV[2];
\$match = 0;
foreach (@{\$cmdopt{\$cmd}})
{
	\$prevCmd = \$arg;
	\$prevCmd =~ s/--//;
	if (\$_ =~ m/^\$prevCmd/) 
	{
		\$match = 1;
		\$noArgs = 0 if m/[=][sfi]/;
		\$optionalArgs = 1 if m/[:][sfi]/;
	}
}
\$match = 1 if (\$cmd eq \$arg) and not \$doAddWords;
s/[=!+:].*// foreach (@{\$cmdopt{\$cmd}});
if (\$noArgs and \$match and not \$doAddWords)
{
	print qq(--\$_\n) foreach( @{\$cmdopt{\$cmd}});
	exit;
}
if (not \$arg =~ m/^--/ and not \$doAddWords)
{
	print qq(--\$_\n) foreach( @{\$cmdopt{\$cmd}});
	exit;
}
%cmdoptMoreWords = (
EOF
;
    $bashFunc = $bashFunc . $cmdoptMoreWordsText;
    $bashFunc = $bashFunc . <<'EOF'	
);
%cmdAddWords = ();
while ((\$key, \$val) = each %{\$cmdoptMoreWords{\$cmd}})
{
	\$cmdAddWords{\$key} = \$val;
}
\$option = \$arg ;
\$option =~ s/--//;

if (defined \$cmdAddWords{\$option}) 
{
	if (\$doAddWords) 
	{
		foreach( @{\$cmdAddWords{\$option}})
		{
			if  (m/^__.*__$/) {
				s/__//g;
				print qq( -A \$_ );
			}		
		}
	}
	else 
	{
		foreach( @{\$cmdAddWords{\$option}})
		{
			print qq(\$_\n) unless m/^__.*__$/;		
		}
	}
}
CMDLINE
)
EOF
;    

    $bashFunc = $bashFunc . <<EOF
    cmdOpts=\$( perl -e "\${perlCmd}" -- "\${subcmd}" "\${prev}")
    cmdAddOpts=\$( perl -e "\${perlCmd}" -- "\${subcmd}" "\${prev}" moreOpts )
    if [[ -z \$cmdAddOpts ]]
    then
		if [[ -z \$cmdOpts ]]
		then
			cmdAddOpts=" -A file "
		fi
	fi
	commas=\$( echo \${cur} | sed "s/\,[^\,]*\$//" )
	cur=\$( echo \${cur} | sed "s/.*\,//" )
	if [ "\$commas" == "\$cur" ]
	then
		COMPREPLY=( \$( compgen \$cmdAddOpts -W "\$cmdOpts" -- "\${cur}") )
	else
		COMPREPLY=( \$( compgen \$cmdAddOpts -W "\$cmdOpts" -- "\${cur}") )	
		LEN=\${#COMPREPLY[@]}
		for ((i=0; i<\${LEN}; i++ ));
		do
			COMPREPLY[\$i]=\$( echo \${commas},\${COMPREPLY[\$i]} )
		done
	fi	
}
complete -F _$scriptName $scriptName
EOF
;

if (-w "/etc/bash_completion.d/$scriptName" or -w "/etc/bash_completion.d/")
{
    open my $fh, '>', "/etc/bash_completion.d/$scriptName"  or die "Can not open /etc/bash_completion.d/$scriptName for writing\n";
    print {$fh} $bashFunc;
    close $fh;
    print qq(Remember to "source /etc/bash_completion.d/$scriptName" to update your shell\n);
} 
else 
{
    print $bashFunc;
}

}


sub parseArgsByPosition
{
    my $argvRef = shift;
    my @argvCopy = @{$argvRef};
    my $dstHashRef = shift;
    my @optSpecs = @_;
    foreach (@optSpecs) {
			my $isList = m/@/;
			my $isHash = m/%/;
            s/[=!+:].*//;
            my $val = shift @argvCopy;
            if ($isList) {
                $dstHashRef->{$_} = [split(/,/, $val)];   
            } elsif ($isHash) {
                $dstHashRef->{$_} = [split(/,|=/, $val)];               
            } else {
                $dstHashRef->{$_} = $val if defined $val;
            }
    }
}

sub parseArgs
{
	# The first argument is a reference to the original 
	# argv list
	# The remaining arguments are the argument specifiers
	# as defined by Getopt::long
	
    my %args     = ();
    my $firstarg = shift;
    my @argvCopy = @{$firstarg};
	# case CGI,  called via CGI return hash parsed by CGI.pm
	if (exists $ENV{GATEWAY_INTERFACE} and scalar(@argvCopy) == 0)
	{
	    %args = %{CGI->new()->Vars};
	    foreach (keys %args) 
	    {
	        $args{$_} = [split(/,|\x{00}/, $args{$_})] if scalar(split(/,|\x{00}/, $args{$_})) > 1;
	    }
	    return %args;
	} 	
	# case One, No arguments, just return
    return if (scalar(@argvCopy) == 0);
	# case Two, the first and only argument is a reference to a hash
	# return a the hash unaltered (named parameter passing)
    %args = %{ $argvCopy[0] } if ( ref( $argvCopy[0] ) eq "HASH" );
    my $ret;
    return %args if ref( $argvCopy[0] ) eq "HASH" and scalar(@argvCopy) == 1;
	
	# case Three, there is one argument and it starts with a dash '-'
	# treat it as a command line string
    if ( ( scalar(@argvCopy) == 1 ) and ( ref( $argvCopy[0] ) eq "" ) and ($argvCopy[0] =~ m/^-/ ))
    {
        $ret = GetOptionsFromString( $argvCopy[0], \%args, @_ );
    }
	# case Four, there is more than one argument, and the 
	# first argument starts with a dash '-'
	# treat it as an array of command line options
    elsif ( (scalar(@argvCopy) != 1) and ( ref( $argvCopy[0] ) eq "" ) and ($argvCopy[0] =~ m/^-/ ))
    {
        $ret = GetOptionsFromArray( \@argvCopy, \%args, @_ );
    }
	# case Five, there is more than one argument and the first argument does not start with a 
	# dash '-' or the first argument is a reference to something
	# OR
	# there is exactly one argument and that argument either:
	# is not a reference to something and does not start with a dash '-'
	# or is a reference to something
	# treat it as a conventional call by position
    else
    {
        parseArgsByPosition( \@argvCopy, \%args, @_);
    }
    my @optSpecs = @_;
	foreach my $arg (keys %args)
	{
		@{$args{$arg}} = split(/,/,join(',',@{$args{$arg}})) if (ref $args{$arg} eq "ARRAY") 
	}
    return %args;
}

sub checkArgs
{
    my @MissingArgs = ();
    my $argRef      = shift;
    while ( my ( $key, $value ) = each %{$argRef} )
    {
        push @MissingArgs, $key if ( not defined($value) );
    }
    return @MissingArgs;
}


END { } # module clean-up code here (global destructor)
=head1 AUTHOR

Robert Haxton, C<< <robert.haxton at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-getopt-commandlineexports at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Getopt-CommandLineExports>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Getopt::CommandLineExports


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Getopt-CommandLineExports>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Getopt-CommandLineExports>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Getopt-CommandLineExports>

=item * Search CPAN

L<http://search.cpan.org/dist/Getopt-CommandLineExports/>

=item * Code Repository

L<https://code.google.com/p/getopt-cle/>

=back

=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2008-2012 Robert Haxton.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Getopt::CommandLineExports
