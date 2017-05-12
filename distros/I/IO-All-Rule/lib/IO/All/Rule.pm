use 5.010; # re::regexp_pattern
use strict;
use warnings;

package IO::All::Rule;
# ABSTRACT: Iterative, recursive file finder with IO::All
our $VERSION = '0.003'; # VERSION

use Path::Iterator::Rule 0.002;
our @ISA = qw/Path::Iterator::Rule/;

use IO::All;
use namespace::clean;

sub _objectify {
    my ( $self, $path ) = @_;
    return io($path);
}

sub _children {
    my $self = shift;
    my $path = shift;
    # IO::All can't seem to give symlink-path relative children, so
    # we construct the list by hand
    opendir( my $dir, "$path" );
    return map { [ $_, io("$path/$_") ] } grep { $_ ne "." && $_ ne ".." } readdir $dir;
}

1;


# vim: ts=4 sts=4 sw=4 et:

__END__

=pod

=head1 NAME

IO::All::Rule - Iterative, recursive file finder with IO::All

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  use IO::All::Rule;

  my $rule = IO::All::Rule->new; # match anything
  $rule->file->size(">10k");     # add/chain rules

  # iterator interface
  my $next = $rule->iter( @dirs );
  while ( my $file = $next->() ) {
    ...
  }

  # list interface
  for my $file ( $rule->all( @dirs ) ) {
    ...
  }

=head1 DESCRIPTION

This module iterates over files and directories to identify ones matching a
user-defined set of rules.

This is a thin subclass of L<Path::Iterator::Rule> that operates on and returns
L<IO::All> objects instead of bare file paths.

See that module for details on features and usage.

See L</PERFORMANCE> for important caveats.  You might want to use
C<Path::Iterator::Rule> instead.

=head1 EXTENDING

This module may be extended in the same way as C<Path::Iterator::Rule>, but
test subroutines receive C<IO::All> objects instead of strings.

Consider whether you should extend C<Path::Iterator::Rule> or C<IO::All::Rule>.
Extending this module specifically is recommended if your tests rely on having
a C<IO::All> object.

=head1 LEXICAL WARNINGS

If you run with lexical warnings enabled, C<Path::Iterator::Rule> will issue
warnings in certain circumstances (such as a read-only directory that must be
skipped).  To disable these categories, put the following statement at the
correct scope:

  no warnings 'Path::Iterator::Rule';

=head1 PERFORMANCE

Because all files and directories as processed as C<IO::All> objects,
using this module is significantly slower than C<Path::Iterator::Rule>.

If you are scanning tens of thousands of files and speed is a concern, you
might be better off using that instead and only creating objects from
results.

    use IO::All;
    use Path::Iterator::Rule;

    my $rule = Path::Iterator::Rule->new->file->size(">10k");
    my $next = $rule->iter( @dirs );

    while ( my $file = io($next->()) ) {
        ...
    }

Generally, I recommend use this module only if you need to write custom rules
that need C<IO::All> features.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/dagolden/io-all-rule/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/io-all-rule>

  git clone git://github.com/dagolden/io-all-rule.git

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
