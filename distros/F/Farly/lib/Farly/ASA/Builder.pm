package Farly::ASA::Builder;

use 5.008008;
use strict;
use warnings;
use Carp;
use Log::Any qw($log);
use Farly::Builder;
use Farly::ASA::Filter;
use Farly::ASA::Parser;
use Farly::ASA::Annotator;
use Farly::ASA::Rewriter;
use Farly::ASA::Generator;
use Farly::ASA::PortFormatter;
use Farly::ASA::ProtocolFormatter;
use Farly::ASA::ICMPFormatter;

our $VERSION = '0.26';
our @ISA     = 'Farly::Builder';

sub new {
    my ($class) = @_;

    #call the constructor of the parent class
    my $self = $class->SUPER::new();
    bless $self, $class;
    
    $log->info("$self NEW");

    return $self;
}

sub run {
    my ($self) = @_;

    my $filter    = Farly::ASA::Filter->new();
    my $parser    = Farly::ASA::Parser->new();
    my $annotator = Farly::ASA::Annotator->new();
    my $rewriter  = Farly::ASA::Rewriter->new();
    my $generator = Farly::ASA::Generator->new();

    $filter->set_file( $self->file() );

    my @preprocessed_file = $filter->run();

    confess "configuration not recognized"
      unless ( scalar(@preprocessed_file) > 0 );

    my $parse_tree;

    foreach my $line (@preprocessed_file) {

        eval {

            #get the parse tree for the current line
            $parse_tree = $parser->parse($line);

            #turn the tokens into objects
            $annotator->visit($parse_tree);

            #rewrite the parse tree into an abstract syntax tree (AST)
            my $ast = $rewriter->rewrite($parse_tree);

            #convert the AST into an Farly::Object object
            #which is stored in the generator's container object
            $generator->visit($ast);
        };
        if ($@) {
            my $err = $@;
            $log->fatal( $self->file() . "\n: $line \n $err\n" );
            chomp($line);
            die "Problem at line :\n$line\nError : $@";
        }

    }

    $self->{CONTAINER} = $generator->container();

    return;
}

sub result {
    return $_[0]->{CONTAINER};
}

1;
__END__

=head1 NAME

Farly::ASA::Builder - Vendor specific concrete builder class

=head1 DESCRIPTION

Farly::ASA::Builder is a concrete builder which handles the process of
converting a Cisco ASA firewall configuration into the corresponding
Farly::Object::List<Farly::Object> firewall device model.

It accepts an firewall configuration IO::File object and returns the
Farly::Object::List<Farly::Object> model when finished.

Farly::ASA::Builder dies on error, highlighting the line of configuration
which caused the exception.

Farly::ASA::Builder is used by the Farly factory class only.

=head1 COPYRIGHT AND LICENCE

Farly::ASA::Builder
Copyright (C) 2012  Trystan Johnson

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
