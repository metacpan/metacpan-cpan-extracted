package Git::Validate;
$Git::Validate::VERSION = '0.001001';
# ABSTRACT: Validate Git Commit Messages

use IPC::System::Simple 'capture';
use Module::Runtime 'use_module';

use Moo;

use namespace::clean;

sub _get_commit_message { capture(qw(git log -1 --pretty=%B), $_[1]) }

sub validate_commit {
   my ($self, $commit) = @_;

   $self->validate_message(
      $self->_get_commit_message($commit)
   )
}

sub validate_message {
   my ($self, $message) = @_;

   my @lines = split /\n/, $message;

   my @e;

   # check tense?
   # check initial case?
   push @e, use_module('Git::Validate::Error::LongLine')
      ->new( line => $lines[0], max_length => 50 )
         if length $lines[0] > 50;

   push @e, use_module('Git::Validate::Error::MissingBreak')
      ->new( line => $lines[1] )
         if $lines[1];

   my $i = 2;
   for my $l (@lines[2..$#lines]) {
      $i++;
      push @e, use_module('Git::Validate::Error::LongLine')
         ->new( line => $l, line_number => $i )
            if $l =~ m/^\S/ && length $l > 72;
   }

   use_module('Git::Validate::Errors')->new(errors => \@e)
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::Validate - Validate Git Commit Messages

=head1 VERSION

version 0.001001

=head1 SYNOPSIS

 use Git::Validate;

 my $validator = Git::Validate->new;
 my $errors = $validator->validate_commit('HEAD');

 die "$errors\n" if $errors;

Or if you want to be all classy and modern:

 for $e (@{$errors->errors}) {
    warn $e->line . " longer than " . $e->max_length . " characters!\n"
      if $e->isa('Git::Validate::Error::LongLine')
 }

=head1 DESCRIPTION

While many users apparently don't know it, there are actual correct ways to
write a C<git> commit message.  For a good summary of why, read
L<this blog post|http://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html>.

This module does its best to automatically check commit messages against The
Rules.  The current automatic checks are:

=over 2

=item * First line should be 50 or fewer characters

=item * Second line should be blank

=item * Third and following lines should be less than 72 characters

=back

=head1 METHODS

=head2 C<validate_commit>

 my $errors = $validator->validate_commit('HEAD');

returns L</ERRORS> for a given commit

=head2 C<validate_message>

 my $errors = $validator->validate_message($commit_message);

returns L</ERRORS> for a given message

=head1 ERRORS

The object containing errors conveniently C<stringifies> and C<boolifies>.  If
you need more information, please please please don't try to parse the returned
strings.  Instead, note that the errors returned are a set of objects.  These
are the objects you can check for:

=over 2

=item * C<Git::Validate::Error::LongLine>

=item * C<Git::Validate::Error::MissingBreak>

=back

The objects can be accessed with the C<errors> method, which returns an
arrayref.  The objects have C<line> and C<line_number> methods.
The C<::LongLine> objects have a C<max_length> method as well.

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
