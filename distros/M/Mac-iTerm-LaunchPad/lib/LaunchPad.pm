#!/usr/bin/perl
use strict;

use warnings;
no warnings;

package Mac::iTerm::LaunchPad;

our $VERSION = 1.008;

#sprintf "%d.%03d", q$Revision: 2499 $ =~ m/(\d+) \. (\d+)/x;

=head1 NAME

new-iterm - open a new iTerm window with one or more tabs

=head1 SYNOPSIS

	---Frontmost finder directory, defaulting to desktop
	% new-iterm

	---Frontmost finder directory, using special alias
	% new-iterm finder
	
	---Named directory
	% new-iterm /Users/brian/Dev

	---Named directory with
	% new-iterm ~/Dev
	
	---Multiple tabs 
	% new-iterm ~/Dev ~/Foo ~/Bar
	
	---Aliases, predefined in code
	% new-iterm music applications
	
	---Aliases, defined in your own ~/.new-iterm-aliases
	% new-iterm foo bar baz
	
	---Any combination
	% new-iterm finder /Users/brian/Dev music ~/Pictures foo
	
	---From other commands
	% perldoc -l Mac::Glue | xargs dirname | xargs new-iterm
	
=head1 DESCRIPTION

This script opens a new iTerm window and creates a tab for each
directory. Within each tab, it changes to that directory. It allows
you to use aliases (not the filesystem sort, the nickname sort) to
save on typing. Without arguments it finds the frontmost finder window
and uses that as the directory. The special directory named "finder"
does the same thing (so you're stuck if you have a directory with that
name: give it a different alias).

=head2 Modulino

This script is actually a modulino. It's a symlink to the
C<Mac::iTerm::LaunchPad> module. That module figures out if it's run
as a script or included as a module and does the right thing. If you
want to change the program, edit the module.

If you don't like that idea, use the included F<scripts/new-iterm>
program which does the same thing without the symlink.

=head2 Aliases

You can define aliases in the F<~/.new-iterm-aliases> file. The file
is line-oriented and has the alias followed by its directory. You can
use the ~ home directory shortcut. 

	#alias	directory
	cpan /mirrors/MINICPAN
	dev	~/Dev
	paypal ~/Personal/Finances/PayPal
	
Since Mac OS X uses a case insenstive (though preserving) file system,
case doesn't matter. If you tricked Mac OS X into using something else,
use the right case and remove the C<lc()> in the code.

=head3 Default aliases

=over 4

=item desktop - the Desktop folder of the current user ( ~/Desktop )

=item home - home directory of the current user ( ~ )

=item music - music directory of the current user ( ~/Music )

=item applications - music directory of the current user ( ~/Applications )

=item finder - the directory of the frontmost finder window (defaults to Desktop)

=back

=head1 TO DO

=over 4

=item switch to choose session name (currently just default)

=item switch to specify tabs or new windows?

=back

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

Inspired by a script from Chris Nandor (http://use.perl.org/~pudge/journal/32199) 
which was inspired by a script from Curtis "Ovid" Poe 
(http://use.perl.org/~Ovid/journal/32086).

=head1 COPYRIGHT AND LICENSE

Copyright 2007, brian d foy.

You may use this program under the same terms as Perl itself.

Some parts come from Chris Nandor and are noted in the source. They are
available under the same license.

=head1 SEE ALSO

iTerm - http://iterm.sourceforge.net/

=cut

# defaults
my %Aliases = qw(
	desktop  		~/Desktop
	home     		~
	music    		~/Music
	applications	/Applications
	);

_run() unless caller;

sub _run {

_init();
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #	
# argument processing

foreach my $arg ( @ARGV )
	{
	my $cwd = do {
		if( defined $arg )
			{
			# don't lc() if you have a case sensitive file system
			$arg = lc( exists $Aliases{$arg} ? $Aliases{$arg} : $arg );
			$arg = _get_finder_dir() if $arg eq 'finder';
			
			if( -d $arg ) { $arg }
			else          { die "$arg isn't a directory!\n" }
			}
		else
			{
			_get_finder_dir();
			}
		};
	
	_launch_iterm( $cwd );
	}
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #	
sub _init
	{
	@ARGV = ( undef ) unless @ARGV; # finder window special case;

	foreach my $key ( keys %Aliases ) { $Aliases{$key} =~ s/^~/$ENV{HOME}/ }
	
	print Dumper ( \%Aliases );
	
	if( open my($fh), "<", "$ENV{HOME}/.new-iterm-aliases" )
		{
		while( <$fh> )
			{
			s/^\s|\s$//g;
			s|(?<!\\)#|.*|;
			next unless /\S\s+\S/;
			my( $alias, $dir ) = map { lc } split;
			$dir =~ s/^~/$ENV{HOME}/;
			$Aliases{$alias} = $dir;
			}
		}	
	}
	
sub _get_finder_dir
	{
	use Mac::Files;

	# from Chris Nandor
	my $finder = new Mac::Glue 'Finder';
	my $cwd = $finder->prop(target => window => 1)->get(as => 'alias');
	$cwd ||= FindFolder(kUserDomain, kDesktopFolderType); # default to Desktop
	$cwd =~ s/'/'\\''/g;
	$cwd;
	}
	
BEGIN {
use Mac::Glue ':all';

my $iterm = eval { Mac::Glue->new( 'iTerm' ) };
if( $@ ) { die "Could not load iTerm definitions for Mac::Glue!: $@" }

$iterm->activate;
my $term = $iterm->make( new => 'terminal' );
my $session = 1;

sub _launch_iterm
	{
	my $cwd = shift;
	
	$term->Launch( session => 'default' );
	$term->obj( session => $session++ )->write(text => "cd '$cwd'");
	}
}