use strict;
use warnings;
package File::TreeBuilder_T;
BEGIN {
  $File::TreeBuilder_T::VERSION = '0.02';
}
# ABSTRACT: Test the File::TreeBuilder module.

# --------------------------------------------------------------------
use Test::Usage;
use File::TreeBuilder qw(build_tree);
use File::Temp;

# --------------------------------------------------------------------
sub exp_file {
    my ($file) = @_;
    ok(
        -f $file,
        "Expected file '$file' to exist,",
        "But it didn't."
    );
}

# --------------------------------------------------------------------
sub exp_dir {
    my ($dir) = @_;
    ok(
        -d $dir,
        "Expected directory '$dir' to exist,",
        "But it didn't."
    );
}

# --------------------------------------------------------------------
sub exp_result {
    my ($exp_result, $got_result) = @_;
    ok(
        scalar($got_result =~ /\Q$exp_result/),
        "Expected result '$exp_result',",
        "But got '$got_result'."
    );
}

# --------------------------------------------------------------------
example('e1', sub {
    exp_result("Directory not defined", build_tree());
});

# --------------------------------------------------------------------
example('a1', sub {
    my $dir = File::Temp->newdir();
    exp_dir($dir);
        # An empty template should succeed, doing nothing.
    exp_result("", build_tree($dir));
});

# --------------------------------------------------------------------
example('a2', sub {
    my $dir = File::Temp->newdir();
    exp_result("", build_tree($dir, << "EOT"));
    / 'foo'
        . 'bar'
EOT
    exp_dir($dir);
    exp_dir("$dir/foo");
    exp_file("$dir/foo/bar");
});

# --------------------------------------------------------------------
example('a3', sub {
    my $dir = File::Temp->newdir();
    exp_result("", build_tree($dir, << 'EOT'));
    / "foo qux"
        . "bar baz"
    / "foo ' qux"
        . "bar' baz", "moo"
EOT
    exp_dir($dir);
    exp_dir("$dir/foo qux");
    exp_file("$dir/foo qux/bar baz");
    exp_dir(qq{$dir/foo ' qux});
    exp_file(qq{$dir/foo ' qux/bar' baz});
});

# --------------------------------------------------------------------
example('a4', sub {
    my $dir = File::Temp->newdir();
    our $bad_filename = 'moo' x 100;
    exp_result("Couldn't open", build_tree($dir, << 'EOT'));
    . $bad_filename
EOT
});

# --------------------------------------------------------------------
1;

__END__
=pod

=head1 NAME

File::TreeBuilder_T - Test the File::TreeBuilder module.

=head1 VERSION

version 0.02

=head1 SYNOPSIS

        # See Test::Usage for details.
    perl -I.. -MFile::TreeBuilder_T -e "test(a => q[*])"

=head1 AUTHOR

Luc St-Louis <lucs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Luc St-Louis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

