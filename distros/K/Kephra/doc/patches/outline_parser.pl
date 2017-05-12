#!/usr/bin/perl
use strict;
use warnings;
use PPI;
use PPI::Dumper;

my $file = shift @ARGV;
my $doc = PPI::Document->new($file) or die "Could not open file: $!";
parse_package($doc);
print "  O\n";

sub parse_package {    # find out the package name, if none, assume main.
    my $tree     = shift;
    my $packages = $tree->find_first('PPI::Statement::Package');
    if ($packages) {
        my $words = $packages->find('PPI::Token::Word');
        print "[P] " . $$words[1] . "\n";
        parse_includes($tree);
        print "  |\n";
        parse_subs($tree);
        print "  |\n";
        parse_shedules($tree);

        #parse_shedules()...
    }
    else {
        print "[P] main:\n";
        parse_includes($tree);
        print "  |\n";
        parse_subs($tree);
        print "  |\n";
        parse_shedules($tree);

        # ... continue parsing.
    }

}

sub parse_includes {    # parse use/require statements.
    my $tree = shift;
    my $includes = $tree->find('PPI::Statement::Include') or return;
    foreach my $include (@$includes) {
        #my $name = ${ $include->find('PPI::Token::Word') }[1];
        print "  `- [I] $include\n";
    }
}

sub parse_subs {        # parse subroutines.
    my $tree = shift;
    my $subs = $tree->find('PPI::Statement::Sub') or return;

    foreach my $sub (@$subs) {
        next if $sub->isa('PPI::Statement::Scheduled');
        my $subroutine_name      = ${ $sub->find('PPI::Token::Word') }[1];
        my $subroutine_prototype = $sub->find_first('PPI::Token::Prototype');
        my $comment              = parse_comment($sub);
        print "  `- [S] $subroutine_name $subroutine_prototype\t$comment\n";
        parse_variables($sub);
    }
}

sub parse_shedules {    # parse BEGIN/END/INITCHECK blocks etc.
    my $tree = shift;
    my $subs = $tree->find('PPI::Statement::Scheduled') or return;
    foreach my $sub (@$subs) {
        my $blockname = $sub->find_first('PPI::Token::Word');
        print "  `- [B] $blockname\n";
        parse_variables($sub);
    }
}

sub parse_variables {    # parse variables from any subset of the tree.
    my $tree = shift;
    my $declarations = $tree->find('PPI::Statement::Variable') or return;

    foreach my $declaration ( @{$declarations} ) {
        my $type_of_declaration = $declaration->find_first('PPI::Token::Word');
        my $variable_name = $declaration->find_first('PPI::Token::Symbol');
        print "  |   `- [D] $type_of_declaration $variable_name\n";
    }
}

sub parse_comment {      # prints the first comment in some subset of the tree.
    my $tree = shift;
    my $comment = $tree->find_first('PPI::Token::Comment') or return "";
    return $comment->content();
}
