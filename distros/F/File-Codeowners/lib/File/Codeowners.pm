package File::Codeowners;
# ABSTRACT: Read and write CODEOWNERS files

use v5.10.1;    # defined-or
use warnings;
use strict;

use Encode qw(encode);
use Path::Tiny 0.089;
use Scalar::Util qw(openhandle);
use Text::Gitignore qw(build_gitignore_matcher);

our $VERSION = '0.53'; # VERSION

sub _croak { require Carp; Carp::croak(@_); }
sub _usage { _croak("Usage: @_\n") }


sub new {
    my $class = shift;
    my $self  = bless {}, $class;
}


sub parse {
    my $self  = shift;
    my $input = shift or _usage(q{$codeowners->parse($input)});

    return $self->parse_from_array($input, @_) if @_;
    return $self->parse_from_array($input)  if ref($input) eq 'ARRAY';
    return $self->parse_from_string($input) if ref($input) eq 'SCALAR';
    return $self->parse_from_fh($input)     if openhandle($input);
    return $self->parse_from_filepath($input);
}


sub parse_from_filepath {
    my $self = shift;
    my $path = shift or _usage(q{$codeowners->parse_from_filepath($filepath)});

    $self = bless({}, $self) if !ref($self);

    return $self->parse_from_fh(path($path)->openr_utf8);
}


sub parse_from_fh {
    my $self = shift;
    my $fh   = shift or _usage(q{$codeowners->parse_from_fh($fh)});

    $self = bless({}, $self) if !ref($self);

    my @lines;

    my $parse_unowned;
    my %unowned;
    my $current_project;

    while (my $line = <$fh>) {
        my $lineno = $. - 1;
        chomp $line;
        if ($line eq '### UNOWNED (File::Codeowners)') {
            $parse_unowned++;
            last;
        }
        elsif ($line =~ /^\h*#(.*)/) {
            my $comment = $1;
            my $project;
            if ($comment =~ /^\h*Project:\h*(.+?)\h*$/i) {
                $project = $current_project = $1 || undef;
            }
            $lines[$lineno] = {
                comment => $comment,
                $project ? (project => $project) : (),
            };
        }
        elsif ($line =~ /^\h*$/) {
            # blank line
        }
        elsif ($line =~ /^\h*(.+?)(?<!\\)\h+(.+)/) {
            my $pattern = $1;
            my @owners  = $2 =~ /( (?:\@+"[^"]*") | (?:\H+) )/gx;
            $lines[$lineno] = {
                pattern => $pattern,
                owners  => \@owners,
                $current_project ? (project => $current_project) : (),
            };
        }
        else {
            die "Parse error on line $.: $line\n";
        }
    }

    if ($parse_unowned) {
        while (my $line = <$fh>) {
            chomp $line;
            if ($line =~ /# (.+)/) {
                my $filepath = $1;
                $unowned{$filepath}++;
            }
        }
    }

    $self->{lines} = \@lines;
    $self->{unowned} = \%unowned;

    return $self;
}


sub parse_from_array {
    my $self = shift;
    my $arr  = shift or _usage(q{$codeowners->parse_from_array(\@lines)});

    $self = bless({}, $self) if !ref($self);

    $arr = [$arr, @_] if @_;
    my $str = join("\n", @$arr);
    return $self->parse_from_string(\$str);
}


sub parse_from_string {
    my $self = shift;
    my $str  = shift or _usage(q{$codeowners->parse_from_string(\$string)});

    $self = bless({}, $self) if !ref($self);

    my $ref = ref($str) eq 'SCALAR' ? $str : \$str;
    open(my $fh, '<:encoding(UTF-8)', $ref) or die "open failed: $!";

    return $self->parse_from_fh($fh);
}


sub write_to_filepath {
    my $self = shift;
    my $path = shift or _usage(q{$codeowners->write_to_filepath($filepath)});

    path($path)->spew_utf8([map { "$_\n" } @{$self->write_to_array}]);
}


sub write_to_fh {
    my $self    = shift;
    my $fh      = shift or _usage(q{$codeowners->write_to_fh($fh)});
    my $charset = shift;

    for my $line (@{$self->write_to_array($charset)}) {
        print $fh "$line\n";
    }
}


sub write_to_string {
    my $self    = shift;
    my $charset = shift;

    my $str = join("\n", @{$self->write_to_array($charset)}) . "\n";
    return \$str;
}


sub write_to_array {
    my $self    = shift;
    my $charset = shift;

    my @format;

    for my $line (@{$self->_lines}) {
        if (my $comment = $line->{comment}) {
            push @format, "#$comment";
        }
        elsif (my $pattern = $line->{pattern}) {
            my $owners = join(' ', @{$line->{owners}});
            push @format, "$pattern  $owners";
        }
        else {
            push @format, '';
        }
    }

    my @unowned = sort keys %{$self->_unowned};
    if (@unowned) {
        push @format, '' if $format[-1];
        push @format, '### UNOWNED (File::Codeowners)';
        for my $unowned (@unowned) {
            push @format, "# $unowned";
        }
    }

    if (defined $charset) {
        $_ = encode($charset, $_) for @format;
    }
    return \@format;
}


sub match {
    my $self     = shift;
    my $filepath = shift or _usage(q{$codeowners->match($filepath)});

    my $lines = $self->{match_lines} ||= [reverse grep { ($_ || {})->{pattern} } @{$self->_lines}];

    for my $line (@$lines) {
        my $matcher = $line->{matcher} ||= build_gitignore_matcher([$line->{pattern}]);
        return {    # deep copy
            pattern => $line->{pattern},
            owners  => [@{$line->{owners} || []}],
            $line->{project} ? (project => $line->{project}) : (),
        } if $matcher->($filepath);
    }

    return undef;   ## no critic (Subroutines::ProhibitExplicitReturn)
}


sub owners {
    my $self    = shift;
    my $pattern = shift;

    return $self->{owners} if !$pattern && $self->{owners};

    my %owners;
    for my $line (@{$self->_lines}) {
        next if $pattern && $line->{pattern} && $pattern ne $line->{pattern};
        $owners{$_}++ for (@{$line->{owners} || []});
    }

    my $owners = [sort keys %owners];
    $self->{owners} = $owners if !$pattern;

    return $owners;
}


sub patterns {
    my $self  = shift;
    my $owner = shift;

    return $self->{patterns} if !$owner && $self->{patterns};

    my %patterns;
    for my $line (@{$self->_lines}) {
        next if $owner && !grep { $_ eq $owner  } @{$line->{owners} || []};
        my $pattern = $line->{pattern};
        $patterns{$pattern}++ if $pattern;
    }

    my $patterns = [sort keys %patterns];
    $self->{patterns} = $patterns if !$owner;

    return $patterns;
}


sub projects {
    my $self  = shift;

    return $self->{projects} if $self->{projects};

    my %projects;
    for my $line (@{$self->_lines}) {
        my $project = $line->{project};
        $projects{$project}++ if $project;
    }

    my $projects = [sort keys %projects];
    $self->{projects} = $projects;

    return $projects;
}


sub update_owners {
    my $self    = shift;
    my $pattern = shift;
    my $owners  = shift;
    $pattern && $owners or _usage(q{$codeowners->update_owners($pattern => \@owners)});

    $owners = [$owners] if ref($owners) ne 'ARRAY';

    $self->_clear;

    my $count = 0;

    for my $line (@{$self->_lines}) {
        next if !$line->{pattern};
        next if $pattern ne $line->{pattern};
        $line->{owners} = [@$owners];
        ++$count;
    }

    return $count;
}


sub update_owners_by_project {
    my $self    = shift;
    my $project = shift;
    my $owners  = shift;
    $project && $owners or _usage(q{$codeowners->update_owners_by_project($project => \@owners)});

    $owners = [$owners] if ref($owners) ne 'ARRAY';

    $self->_clear;

    my $count = 0;

    for my $line (@{$self->_lines}) {
        next if !$line->{project} || !$line->{owners};
        next if $project ne $line->{project};
        $line->{owners} = [@$owners];
        ++$count;
    }

    return $count;
}


sub rename_owner {
    my $self        = shift;
    my $old_owner   = shift;
    my $new_owner   = shift;
    $old_owner && $new_owner or _usage(q{$codeowners->rename_owner($owner => $new_owner)});

    $self->_clear;

    my $count = 0;

    for my $line (@{$self->_lines}) {
        next if !exists $line->{owners};
        for (my $i = 0; $i < @{$line->{owners}}; ++$i) {
            next if $line->{owners}[$i] ne $old_owner;
            $line->{owners}[$i] = $new_owner;
            ++$count;
        }
    }

    return $count;
}


sub rename_project {
    my $self        = shift;
    my $old_project = shift;
    my $new_project = shift;
    $old_project && $new_project or _usage(q{$codeowners->rename_project($project => $new_project)});

    $self->_clear;

    my $count = 0;

    for my $line (@{$self->_lines}) {
        next if !exists $line->{project} || $old_project ne $line->{project};
        $line->{project} = $new_project;
        $line->{comment} = " Project: $new_project" if exists $line->{comment};
        ++$count;
    }

    return $count;
}


sub append {
    my $self = shift;
    $self->_clear;
    push @{$self->_lines}, (@_ ? {@_} : undef);
}


sub prepend {
    my $self = shift;
    $self->_clear;
    unshift @{$self->_lines}, (@_ ? {@_} : undef);
}


sub unowned {
    my $self = shift;
    [sort keys %{$self->{unowned} || {}}];
}


sub add_unowned {
    my $self = shift;
    $self->_unowned->{$_}++ for @_;
}


sub remove_unowned {
    my $self = shift;
    delete $self->_unowned->{$_} for @_;
}



sub is_unowned {
    my $self     = shift;
    my $filepath = shift;
    $self->_unowned->{$filepath};
}


sub clear_unowned {
    my $self = shift;
    $self->{unowned} = {};
}

sub _lines   { shift->{lines}   ||= [] }
sub _unowned { shift->{unowned} ||= {} }

sub _clear {
    my $self = shift;
    delete $self->{match_lines};
    delete $self->{owners};
    delete $self->{patterns};
    delete $self->{projects};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::Codeowners - Read and write CODEOWNERS files

=head1 VERSION

version 0.53

=head1 METHODS

=head2 new

    $codeowners = File::Codeowners->new;

Construct a new L<File::Codeowners>.

=head2 parse

    $codeowners = File::Codeowners->parse('path/to/CODEOWNERS');
    $codeowners = File::Codeowners->parse($filehandle);
    $codeowners = File::Codeowners->parse(\@lines);
    $codeowners = File::Codeowners->parse(\$string);

Parse a F<CODEOWNERS> file.

This is a shortcut for the C<parse_from_*> methods.

=head2 parse_from_filepath

    $codeowners = File::Codeowners->parse_from_filepath('path/to/CODEOWNERS');

Parse a F<CODEOWNERS> file from the filesystem.

=head2 parse_from_fh

    $codeowners = File::Codeowners->parse_from_fh($filehandle);

Parse a F<CODEOWNERS> file from an open filehandle.

=head2 parse_from_array

    $codeowners = File::Codeowners->parse_from_array(\@lines);

Parse a F<CODEOWNERS> file stored as lines in an array.

=head2 parse_from_string

    $codeowners = File::Codeowners->parse_from_string(\$string);
    $codeowners = File::Codeowners->parse_from_string($string);

Parse a F<CODEOWNERS> file stored as a string. String should be UTF-8 encoded.

=head2 write_to_filepath

    $codeowners->write_to_filepath($filepath);

Write the contents of the file to the filesystem atomically.

=head2 write_to_fh

    $codeowners->write_to_fh($fh);

Format the file contents and write to a filehandle.

=head2 write_to_string

    $scalarref = $codeowners->write_to_string;

Format the file contents and return a reference to a formatted string.

=head2 write_to_array

    $lines = $codeowners->write_to_array;

Format the file contents as an arrayref of lines.

=head2 match

    $owners = $codeowners->match($filepath);

Match the given filepath against the available patterns and return just the
owners for the matching pattern. Patterns are checked in the reverse order
they were defined in the file.

Returns C<undef> if no patterns match.

=head2 owners

    $owners = $codeowners->owners; # get all defined owners
    $owners = $codeowners->owners($pattern);

Get an arrayref of owners defined in the file. If a pattern argument is given,
only owners for the given pattern are returned (or empty arrayref if the
pattern does not exist). If no argument is given, simply returns all owners
defined in the file.

=head2 patterns

    $patterns = $codeowners->patterns;
    $patterns = $codeowners->patterns($owner);

Get an arrayref of all patterns defined.

=head2 projects

    $projects = $codeowners->projects;

Get an arrayref of all projects defined.

=head2 update_owners

    $codeowners->update_owners($pattern => \@new_owners);

Set a new set of owners for a given pattern. If for some reason the file has
multiple such patterns, they will all be updated.

Nothing happens if the file does not already have at least one such pattern.

=head2 update_owners_by_project

    $codeowners->update_owners_by_project($project => \@new_owners);

Set a new set of owners for all patterns under the given project.

Nothing happens if the file does not have a project with the given name.

=head2 rename_owner

    $codeowners->rename_owner($old_name => $new_name);

Rename an owner.

Nothing happens if the file does not have an owner with the old name.

=head2 rename_project

    $codeowners->rename_project($old_name => $new_name);

Rename a project.

Nothing happens if the file does not have a project with the old name.

=head2 append

    $codeowners->append(comment => $str);
    $codeowners->append(pattern => $pattern, owners => \@owners);
    $codeowners->append();     # blank line

Append a new line.

=head2 prepend

    $codeowners->prepend(comment => $str);
    $codeowners->prepend(pattern => $pattern, owners => \@owners);
    $codeowners->prepend();    # blank line

Prepend a new line.

=head2 unowned

    $filepaths = $codeowners->unowned;

Get the list of filepaths in the "unowned" section.

This parser supports an "extension" to the F<CODEOWNERS> file format which
lists unowned files at the end of the file. This list can be useful to have in
order to figure out what files we know are unowned versus what files we don't
know are unowned.

=head2 add_unowned

    $codeowners->add_unowned($filepath, ...);

Add one or more filepaths to the "unowned" list.

This method does not check to make sure the filepath(s) actually do not match
any patterns in the file, so you might want to call L</match> first.

See L</unowned> for an explanation.

=head2 remove_unowned

    $codeowners->remove_unowned($filepath, ...);

Remove one or more filepaths from the "unowned" list.

Silently ignores filepaths that are already not listed.

See L</unowned> for an explanation.

=head2 is_unowned

    $bool = $codeowners->is_unowned($filepath);

Test whether a filepath is in the "unowned" list.

See L</unowned> for an explanation.

=head2 clear_unowned

    $codeowners->clear_unowned;

Remove all filepaths from the "unowned" list.

See L</unowned> for an explanation.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/chazmcgarvey/File-Codeowners/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Charles McGarvey <chazmcgarvey@brokenzipper.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Charles McGarvey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
