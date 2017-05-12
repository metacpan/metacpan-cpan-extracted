package JBD::Core::Template;
# ABSTRACT: provides render, which merges a template file and replacements
our $VERSION = '0.04'; # VERSION

#/ Provides render(), which takes a template file and its
#/ (placeholder, value) pairs, and renders the template.
#/ @author Joel Dalley
#/ @version 2013/Oct/27

use JBD::Core::stern;
use Carp 'croak';
use File::Slurp;

use Exporter 'import';
our @EXPORT_OK = qw(render);

my %cache;


#///////////////////////////////////////////////////////////////
#/ Interface ///////////////////////////////////////////////////

#/ @param string $file    a template file path
#/ @param hash [optional] %repl    placeholder/value pairs
sub render($;%) {
    my ($file, %repl) = (shift, @_);

    #/ load
    exists $cache{$file} or do {
        $cache{$file} = read_file $file 
            or croak "No such template file `$file`";
    };

    #/ replace
    my $text = $cache{$file};
    while (my ($k, $v) = each %repl) { $text =~ s/$k/$v/g }

    $text;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JBD::Core::Template - provides render, which merges a template file and replacements

=head1 VERSION

version 0.04

=head1 AUTHOR

Joel Dalley <joeldalley@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Joel Dalley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
