package Git::Hooks::RubyNoDebugger;

use strict;
use warnings;

use Git::Hooks;

our $VERSION = '0.01';

my $debug = qr/^[^#"'.]* (?: (?: binding\.pry | byebug | debug(?:ger)? ) [(\s@[{:] ) /x;
my $extention = qr/\.(?:erb|haml|hbs|handlebars|rake|rb|ru|rhtml|slim|thor)$/;

sub check_commit
{
    my $git   = shift;
    my @files = $git->filter_files_in_index('AM');

    my $success = 1;

    $git->nocarp;
    # $git->get_config;

    for my $file (@files) {
	next unless $file =~ /$extention/;

	open my $in, '<', $file or die $!;

	while(my $line = <$in>) {
	    if($line =~ /$debug/) {
		chomp $line;	# TODO: fix regex, it's now dependent on the newline.
		$git->error(__PACKAGE__, "found debug statement '$line' in $file at line $.");

		$success = 0;
	    }
	}

	close $in;
    }

    return $success;
}

PRE_COMMIT \&check_commit;

1;

=pod

=head1 NAME

Git::Hooks::RubyNoDebugger - Git::Hooks plugin that checks for calls to a Ruby debugger

=head1 DESCRIPTION

C<Git::Hooks::RubyNoDebugger> adds a pre-commit hook that looks for the invocation of a debugger.
If one is detected the commit will be aborted.

=head2 Setup

C<git config --add githooks.plugin RubyNoDebugger>

=head2 File Extensions

Files with the following extensions are checked: erb, haml, hbs, handlebars, rake, rb, ru, rhtml, slim, thor

=head2 Debugger Calls

The following debugger calls are checked: C<binding.pry>, C<byebug>, C<debug>, C<debugger>.

=head1 AUTHOR

Skye Shaw (sshaw [AT] gmail.com)

=head1 SEE ALSO

L<Git::Hooks>

=head1 COPYRIGHT

Copyright (c) 2015 Skye Shaw.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
