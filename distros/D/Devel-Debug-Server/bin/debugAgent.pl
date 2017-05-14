#!/usr/bin/env perl
use strict;
use warnings;
use Devel::Debug::Server::Agent;

# PODNAME: debugAgent.pl

# ABSTRACT: The devel::Debug agent

my $commandToLaunch = join(' ',@ARGV);
Devel::Debug::Server::Agent::loop($commandToLaunch);

1;

__END__

=pod

=head1 NAME

debugAgent.pl - The devel::Debug agent

=head1 VERSION

version 1.001

=head1 SYNOPSIS

	#on command-line
	
	#... first launch the debug server (only once)
	
	tom@house:debugserver.pl 
	
	server is started...
	
	#now launch your script(s) to debug 
	
	tom@house:debugagent.pl path/to/scripttodebug.pl
	
	#in case you have arguments
	
	tom@house:debugagent.pl path/to/scripttodebug.pl arg1 arg2 ...
	
	#now you can send debug commands with the devel::debug::server::client module

=head1 DESCRIPTION

to debug a perl script, simply start the server and launch the script with debugagent.pl.

=head1 SEE ALSO

See L<Devel::Debug::Server> for more informations.

=head1 AUTHOR

Jean-Christian HASSLER <hasslerjeanchristian at gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Jean-Christian HASSLER.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
