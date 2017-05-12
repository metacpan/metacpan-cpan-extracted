package Git::Repository::Plugin::AUTOLOAD;
$Git::Repository::Plugin::AUTOLOAD::VERSION = '1.003';
use warnings;
use strict;
use 5.006;

use Git::Repository::Plugin;
our @ISA = qw( Git::Repository::Plugin );
sub _keywords {qw( AUTOLOAD )}

sub AUTOLOAD {
    my ($self) = shift;

    # get the command name
    ( my $cmd = our $AUTOLOAD ) =~ s/.*:://;
    $cmd =~ y/_/-/;

    # but ignore some commands
    return if $cmd eq 'DESTROY';

    # run it
    return $self->run( $cmd, @_ );
}

1;

__END__

=pod

=head1 NAME

Git::Repository::Plugin::AUTOLOAD - Git subcommands as Git::Repository methods

=head1 SYNOPSIS

    use Git::Repository 'AUTOLOAD';

    my $r = Git::Repository->new();

    $r->add($file);
    $r->commit( '-m' => 'message' );

    # NOTE: might be overridden by the 'Log' plugin
    my $log = $r->log('-1');

    # use "_" for "-" in command names
    my $sha1 = $r->rev_parse('master');

    # can be used as a class method
    Git::Repository->clone( $url );

=head1 DESCRIPTION

This module adds an C<AUTOLOAD> method to L<Git::Repository>, enabling
it to automagically call git commands as methods on L<Git::Repository>
objects.

=head1 METHODS

=head2 AUTOLOAD

Any method call caught by C<AUTOLOAD> will simply turn all C<_>
(underscore) into C<-> (dash), and call C<run()> on the invocant,
with the transformed method name as the first parameter.

For example:

    my $sha1 = $r->rev_parse('master');

does exactly the same thing as:

    my $sha1 = $r->run( 'rev-parse', 'master' );

All parameters to the original method call are kept, so these
autoloaded methods can take option hashes.

Note that C<AUTOLOAD> does not install methods in the invocant class
(but what's the cost of a Perl subroutine call compared to forking a git
subprocess?), so that plugins adding new methods always take precedence.

=head1 SEE ALSO

L<Git::Repository>,
L<Git::Repository::Plugin>.

=head1 AUTHOR

Philippe Bruhat (BooK) <book@cpan.org>.

=head1 COPYRIGHT

Copyright 2014-2016 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
