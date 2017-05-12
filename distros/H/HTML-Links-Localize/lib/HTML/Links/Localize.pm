package HTML::Links::Localize;

use strict;
use warnings;

use 5.008;

use HTML::TokeParser;
use File::Find;
use File::Copy;

use vars qw($VERSION);

$VERSION = "0.2.8";

# Two utility functions
sub _is_older
{
    my $file1 = shift;
    my $file2 = shift;
    my @stat1 = stat($file1);
    my @stat2 = stat($file2);
    return ($stat1[9] <= $stat2[9]);
}

sub _is_newer
{
    my $file1 = shift;
    my $file2 = shift;
    return (! _is_older($file1, $file2));
}

sub new
{
    my $class = shift;
    my $self = {};
    bless $self, $class;

    $self->_init(@_);

    return $self;
}

sub _set_base_dir
{
    my $self = shift;

    my $base_dir = shift;

    $base_dir =~ s{/*$}{/};

    $self->{'base_dir'} = $base_dir;

    return 0;
}

sub _get_base_dir
{
    my $self = shift;

    return $self->{'base_dir'};
}

sub _set_dest_dir
{
    my $self = shift;

    my $dest_dir = shift;

    $self->{'dest_dir'} = $dest_dir;

    return 0;
}

sub _get_dest_dir
{
    my $self = shift;

    return $self->{'dest_dir'};
}

sub _init
{
    my $self = shift;

    my %args = @_;

    $self->_set_base_dir($args{'base_dir'} || ".");

    $self->_set_dest_dir($args{'dest_dir'} || "./dest");

    return 0;
}

sub process_content
{
    my $self = shift;

    my $fh = shift;

    my $out_content = "";

    my $out = sub {
        $out_content .= join("", @_);
    };

    my $parser = HTML::TokeParser->new($fh);
    while (my $token = $parser->get_token())
    {
        my $type = $token->[0];
        if ($type eq "E")
        {
            $out->($token->[2]);
        }
        elsif ($type eq "C")
        {
            $out->($token->[1]);
        }
        elsif ($type eq "T")
        {
            $out->($token->[1]);
        }
        elsif ($type eq "D")
        {
            $out->($token->[1]);
        }
        elsif ($type eq "PI")
        {
            $out->($token->[2]);
        }
        elsif ($type eq "S")
        {
            my $tag = $token->[1];
            my %process_tags =
            (
                'form' => { 'action' => 1 },
                'img' => { 'src' => 1},
                'a' => { 'href' => 1},
                'link' => { 'href' => 1},
            );
            if (exists($process_tags{$tag}))
            {
                my $ret = "<$tag";
                my $attrseq = $token->[3];
                my $attr_values = $token->[2];
                my $process_attrs = $process_tags{$tag};
                foreach my $attr (@$attrseq)
                {
                    my $value = $attr_values->{$attr};
                    if (exists($process_attrs->{$attr}))
                    {
                        # If it's a local link that ends with slash -
                        # then append index.html
                        if (($value !~ /^[a-z]+:/) && ($value !~ /^\//) &&
                            ($value =~ /\/(#[^#\/]*)?$/))
                        {
                            my $pos = rindex($value, "/");
                            substr($value,$pos+1,0) = "index.html";
                        }
                    }
                    if ($attr eq "/")
                    {
                        $ret .= " /";
                    }
                    else
                    {
                        $ret .= " $attr=\"$value\"";
                    }
                }
                $out->($ret);
                $out->(">");
            }
            else
            {
                $out->($token->[4]);
            }
        }
    }

    return $out_content;
}

sub process_file
{
    my $self = shift;
    my $filename = shift;

    my $dest_dir = $self->_get_dest_dir();
    my $src_dir = $self->_get_base_dir();

    open my $in, '<', "$src_dir/$filename"
        or die "Cannot open '$src_dir/$filename' - $!";
    open my $out, '>', "$dest_dir/$filename"
        or die "Cannot open '$dest_dir/$filename' for writing- $!";
    print {$out} $self->process_content($in);
    close($in);
    close($out);
}

sub process_dir_tree
{
    my $self = shift;

    my %args = @_;

    my $should_replace_file = sub {
        my ($src, $dest) = @_;
        if ($args{'only-newer'})
        {
            return ((! -e $dest) || (_is_newer($src, $dest)));
        }
        else
        {
            return 1;
        }
    };

    my $src_dir = $self->_get_base_dir();
    my $dest_dir = $self->_get_dest_dir();

    my (@dirs, @other_files, @html_files);

    my $wanted = sub {
        my $filename = $File::Find::name;
        if (length($filename) < length($src_dir))
        {
            return;
        }
        # Remove the $src_dir from the filename;
        $filename = substr($filename, length($src_dir));

        if (-d $_)
        {
            push @dirs, $filename;
        }
        elsif (/\.html?$/)
        {
            push @html_files, $filename;
        }
        else
        {
            push @other_files, $filename;
        }
    };

    find($wanted, $src_dir);

    my $soft_mkdir = sub {
        my $dir = shift;
        if (-d $dir)
        {
            # Do nothing
        }
        elsif (-e $dir)
        {
            die "$dir exists in destination and is not a directory";
        }
        else
        {
            mkdir($dir) || die "mkdir failed: $!\n";
        }
    };

    # Create the directory structure in $dest

    $soft_mkdir->($dest_dir);
    foreach my $dir (@dirs)
    {
        $soft_mkdir->("$dest_dir/$dir");
    }

    foreach my $file (@other_files)
    {
        my $src = "$src_dir/$file";
        my $dest = "$dest_dir/$file";
        if ($should_replace_file->($src, $dest))
        {
            copy($src, $dest);
        }
    }

    foreach my $file (@html_files)
    {
        my $src = "$src_dir/$file";
        my $dest = "$dest_dir/$file";
        if ($should_replace_file->($src,$dest))
        {
            $self->process_file($file);
        }
    }

    return 0;
}

1;

=head1 NAME

HTML::Links::Localize - Convert HTML Files to be used on a hard disk

=head1 SYNOPSIS

    use HTML::Links::Localize;

    my $converter =
        HTML::Links::Localize->new(
            'base_dir' => "/var/www/html/shlomi/Perl/Newbies/lecture4/",
            'dest_dir' => "./dest"
        );

    $converter->process_file("mydir/myfile.html");

    $converter->process_dir_tree('only-newer' => 1);

    my $new_content = $converter->process_content(\$html_text);

=head1 DESCRIPTION

HTML::Links::Localize converts HTML files to be used when viewing on the
hard disk. Namely, it converts relative links to point to "index.html"
files in their directories.

To use it, first initialize an instance using new:

=head2 $converter = HTML::Links::Localize->new(base_dir => $base_dir, dest_dir => $dest_dir)

The constructor accepts two named parameters which are mandatory.
C<'base_dir'> is the base directory (or source directory) for the
operations. C<'dest_dir'> is the root destination directory.

Afterwards, you can use the other methods.

=head2 $new_content = $converter->process_content(FILE)

This function converts a singular text of an HTML file to a hard disk one.
FILE is any argument accepatble by L<HTML::TokeParser>. It returns
the new content.

=head2 $converter->process_file($filename)

This function converts a filename relative to the source directory to
its corresponding file in the destination directory.

=head2 $converter->process_dir_tree( [ 'only-newer' => 1] );

This function converts the entire directory tree that starts at the
base directory. only-newer means to convert only files that are newer
in a make-like fashion.

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/>

=head1 COPYRIGHT AND LICENSE

Copyright 2004, Shlomi Fish.

You can use, modify and distribute this module under the terms of the MIT X11
license. ( L<http://www.opensource.org/licenses/mit-license.php> ).

=head2 NOTE

The CPAN meta-data says this work is "BSD-licensed". The BSD license was chosen
because it was the closest option to MIT X11, and because the MIT X11 license
is a BSD-style license. However, the correct license is the MIT X11.

=cut

