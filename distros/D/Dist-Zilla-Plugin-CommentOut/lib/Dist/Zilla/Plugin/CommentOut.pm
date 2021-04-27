use strict;
use warnings;
use 5.024;

package Dist::Zilla::Plugin::CommentOut 0.05 {

  # ABSTRACT: Comment out code in your scripts and modules


  use Moose;
  use experimental qw( signatures );

  with (
    'Dist::Zilla::Role::FileMunger',
    'Dist::Zilla::Role::FileFinderUser' => {
      default_finders => [ ':ExecFiles', ':InstallModules' ],
    },
  );

  use namespace::autoclean;

  has id => (
    is      => 'rw',
    isa     => 'Str',
    default => 'dev-only',
  );

  has remove => (
    is      => 'rw',
    isa     => 'Int',
    default => 0,
  );

  has begin => (
    is      => 'rw',
    isa     => 'Str',
  );

  has end => (
    is      => 'rw',
    isa     => 'Str',
  );

  sub munge_files ($self)
  {
    $self->munge_file($_) for $self->found_files->@*;
    return;
  }

  sub munge_file ($self, $file)
  {
    return if $file->is_bytes;

    $self->log("commenting out @{[ $self->id ]} in @{[ $file->name ]}");

    my $content = $file->content;

    my $id = $self->id;

    if($id)
    {
      if($self->remove)
      { $content =~ s/^(.*?#\s*\Q$id\E\s*)$/\n/mg }
      else
      { $content =~ s/^(.*?#\s*\Q$id\E\s*)$/#$1/mg }
    }

    if($self->begin && $self->end)
    {
      my $begin = $self->begin;
      my $end   = $self->end;
      $begin = qr{^\s*#\s*\Q$begin\E\s*$};
      $end   = qr{^\s*#\s*\Q$end\E\s*$};

      my @lines = split /\n/, $content;
      my $in = 0;
      for(@lines)
      {
        if(!$in)
        {
          if($_ =~ $begin)
          {
            $in = 1;
            $_ = '' if $self->remove;
          }
        }
        else
        {
          if($_ =~ $end)
          {
            $in = 0;
            $_ = '' if $self->remove;
          }
          else
          {
            if($self->remove)
            { $_ = '' }
            else
            { s/^/#/ }
          }
        }
      }
      $content = join "\n", @lines, '';
    }

    $file->content($content);
    return;
  }

  __PACKAGE__->meta->make_immutable;

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::CommentOut - Comment out code in your scripts and modules

=head1 VERSION

version 0.05

=head1 SYNOPSIS

 [CommentOut]
 id = dev-only

=head1 DESCRIPTION

This plugin comments out lines of code in your Perl scripts or modules with
the provided identification.  This allows you to have code in your development
tree that gets commented out before it gets shipped by L<Dist::Zilla> as a
tarball.

=head1 MOTIVATION

I use perlbrew and/or perls installed in funny places and I'd like to be able to run
executables out of by git checkout tree without invoking C<perl -Ilib> on
every call.  To that end I write something like this:

 #!/usr/bin/env perl
 
 use strict;
 use warnings;
 use lib::findbin '../lib';  # dev-only
 use App::MyApp;

That is lovely, except that the main toolchain installers EUMM and MB will
convert C</usr/bin/perl> but not C</usr/bin/env perl> to the correct perl
when the distribution is installed.  There
is a handy plugin C<[SetScriptShebang]> that solves that problem but the
C<use lib::findbin '../lib';> is problematic because C<../lib> relative to
the install location might not be right!  With both C<[SetScriptShebang]>
and this plugin, I can fix both problems:

 [SetScriptShebang]
 [CommentOut]

And my script will be converted to:

 #!perl
 
 use strict;
 use warnings;
 #use lib::findbin '../lib';  # dev-only
 use App::MyApp;

Which is the right thing for CPAN.  Since lines are commented out, line numbers
are retained.

=head1 PROPERTIES

=head2 id

The comment id to search for.  The default is C<dev-only>.

=head2 remove

Remove lines instead of comment them out.

=head2 begin

For block comments, the id to use for the beginning of the block.
Block comments are off unless both C<begin> and C<end> are specified.

=head2 end

For block comments, the id to use for the beginning of the block.
Block comments are off unless both C<begin> and C<end> are specified.

=head1 SEE ALSO

=over 4

=item L<Dist::Zilla::Plugin::Comment>

Does something very similar.  I did actually do a survay of Dist::Zilla
plugins before writing this one, but apparently I missed this one.  Anyway
I prefer C<[CommentOut]> as it is configurable.

=back

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Mohammad S Anwar (MANWAR)

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
