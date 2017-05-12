package Lingua::Align::Corpus::Treebank::Berkeley;

use 5.005;
use strict;

use Lingua::Align::Corpus::Treebank::Penn;
use File::Basename;

use vars qw(@ISA);
@ISA = qw(Lingua::Align::Corpus::Treebank::Penn);


sub read_next_sentence{
    my $self=shift;
    my $tree=shift;
    %{$tree}=();

    my $file=shift || $self->{-file};
    if (! defined $self->{FH}->{$file}){
	$self->{FH}->{$file} = $self->open_file($file);
	$self->{-file}=$file;
    }
    my $fh=$self->{FH}->{$file};

    $self->__initialize_parser($tree);
    $tree->{ID}=$self->next_sentence_id();

    while (<$fh>){
	chomp;
	next if ($_!~/\S/);
	s/^\s*\(\s+(\(.*\))\s+\)\s*$/$1/;
	return 1 if ($self->__parse($_,$tree));
    }
    return 0;

}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Lingua::Align::Corpus::Treebank::Penn - Read the output of the Berkeley parser

=head1 SYNOPSIS

=head1 DESCRIPTION

=head2 EXPORT

=head1 SEE ALSO

=head1 AUTHOR

Joerg Tiedemann, E<lt>tiedeman@E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Joerg Tiedemann

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
