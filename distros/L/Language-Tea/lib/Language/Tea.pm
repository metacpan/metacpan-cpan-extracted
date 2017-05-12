package Language::Tea;

use warnings;
use strict;

use lib ( 'lib', '../lib' );

use Language::Tea::Traverse;
use Language::Tea::Grammar;
use Language::Tea::Pad;
use Language::Tea::Match2AST;
use Language::Tea::AST2Objects;
use Language::Tea::NodeUpLinker;
use Language::Tea::StatementContext;
use Language::Tea::ASTRefactor;
use Language::Tea::StaticType;
use Language::Tea::JavaEmitter;
use Language::Tea::Function;
 
=head1 NAME

Language::Tea - A Tea code converter. 

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';
our %Classes;
our $root;

=head1 SYNOPSIS

This module converts Tea code into Java.

syntax:
 
    destea.pl filename [option]

- filename: The Tea file you want to convert.

- option: put any character after the filename if you want destea to print directly to file. This will create a directory named 'Project' with a file MainProgram.java and other files for each class in the Tea file converted.

=head1 DESCRIPTION

destea will convert Tea code to Java. You have two options:
- You can print Java code to standard output;
- Or, you can print Java code directly to java files. If you want to use this, you just have to put any character after the filename

Example:
    ./destea.pl example.java a

This will create a new directory called 'Project' and inside you'll have MainProgram.java, wich contains all main Tea instructions, and you'll have another files, one for each class in your Tea file converted.

Example:
Imagine you have a Tea file with two classes: Triangle and Rectangle.
If you convert this file, you'll obtain MainProgram.java, Triangle.java and Rectangle.java

=cut

sub translate {
    my $source_code= shift; 
    my $filename = shift;
    my @source_lines = shift;

    my $Env = Language::Tea::Pad->new();
    Language::Tea::Function::init_prototypes( $Env );

    $source_code =~ s/{/ { /g;
    $source_code =~ s/\(/ \( /g;
    $source_code =~ s/\)/ \) /g;
    
    my $match = Language::Tea::Grammar->statements( $source_code );
    my $ast = Language::Tea::Match2AST::match2ast( $match, $filename, \@source_lines );
    $root = Language::Tea::AST2Objects::ast2objects( $ast );

    Language::Tea::NodeUpLinker::create_links( $root );
    Language::Tea::StatementContext::annotate_context( $root );
    Language::Tea::ASTRefactor::refactor( $root );
    $root = Language::Tea::StaticType::annotate_types($root, $Env);
    {
        my $i = 0;
        while ( $i < @{ $root->{statement} } ) {
            my $node = $root->{statement}[$i];
            if ( ref( $node ) eq 'TeaPart::Class' ) {
                my $class = $node->{class}{arg_symbol};
                $Classes{$class} ||= $node;  # XXX
                splice @{ $root->{statement} }, $i, 1;
            }
            elsif ( ref( $node ) eq 'TeaPart::Method' ) {
                my $class = $node->{class}{arg_symbol};
                die "undeclared class $class"
                    unless exists $Classes{$class};
                my $method = $node->{method}{arg_symbol};
                push @{ $Classes{$class}{statement} }, $node;
                splice @{ $root->{statement} }, $i, 1;
            }
            else { 
                $i++
            }        
        }
    }
}


sub printMainProg {
    my $package = shift;
    return Language::Tea::JavaEmitter::emit($root, $package);
}


sub printClass {
    my $class = shift;
    return Language::Tea::JavaEmitter::emit($Classes{$class}, $class);
}
 

=head1 AUTHOR

Mario Silva <mario.silva at verticalone.pt>

Flavio Glock <flavio.glock@verticalone.pt>

Daniel Ruoso <daniel.ruoso@verticalone.pt>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-language-tea at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Language-Tea>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Language-Tea>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Language-Tea>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Language-Tea>

=item * Search CPAN

L<http://search.cpan.org/dist/Language-Tea>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2007 Mario Silva, Flavio Glock, Daniel Ruoso, Vertical One all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Language::Tea
