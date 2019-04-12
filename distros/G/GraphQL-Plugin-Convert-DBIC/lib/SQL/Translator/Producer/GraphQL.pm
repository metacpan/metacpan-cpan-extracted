package SQL::Translator::Producer::GraphQL;
use strict;
use warnings;
use GraphQL::Plugin::Convert::DBIC;

our $VERSION = "0.05";

my $dbic_schema_class_track = 'CLASS00000';
sub produce {
  my $translator = shift;
  my $schema = $translator->schema;
  my $dbic_schema_class = ++$dbic_schema_class_track;
  my $dbic_translator = bless { %$translator }, ref $translator;
  $dbic_translator->producer_args({ prefix => $dbic_schema_class });
  my $perl = dbic_produce($dbic_translator);
  eval $perl;
  die "Failed to make DBIx::Class::Schema: $@" if $@;
  my $converted = GraphQL::Plugin::Convert::DBIC->to_graphql($dbic_schema_class->connect);
  $converted->{schema}->to_doc;
}

{
# from SQL::Translator::Producer::DBIx::Class::File;
use SQL::Translator::Schema::Constants;
use SQL::Translator::Utils qw(header_comment);
use Data::Dumper ();

## Skip all column type translation, as we want to use whatever the parser got.

## Translate parsers -> PK::Auto::Foo, however

my %parser2PK = (
                 MySQL       => 'PK::Auto::MySQL',
                 PostgreSQL  => 'PK::Auto::Pg',
                 DB2         => 'PK::Auto::DB2',
                 Oracle      => 'PK::Auto::Oracle',
                 );

sub dbic_produce
{
    my ($translator) = @_;
    my $no_comments    = $translator->no_comments;
    my $add_drop_table = $translator->add_drop_table;
    my $schema         = $translator->schema;
    my $output         = '';

    # Steal the XML producers "prefix" arg for our namespace?
    my $dbixschema     = $translator->producer_args()->{prefix} ||
        $schema->name || 'My::Schema';
    my $pkclass = $parser2PK{$translator->parser_type} || '';

    my %tt_vars = ();
    $tt_vars{dbixschema} = $dbixschema;
    $tt_vars{pkclass} = $pkclass;

    my $schemaoutput .= << "DATA";

package ${dbixschema};
use base 'DBIx::Class::Schema';
use strict;
use warnings;
DATA

    my %tableoutput = ();
    my %tableextras = ();
    foreach my $table ($schema->get_tables)
    {
        my $tname = $table->name;
        my $output .= qq{

package ${dbixschema}::${tname};
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/${pkclass} Core/);
__PACKAGE__->table('${tname}');

};

        my @fields = map
        {
        { $_->name  => {
            name              => $_->name,
            is_auto_increment => $_->is_auto_increment,
            is_foreign_key    => $_->is_foreign_key,
            is_nullable       => $_->is_nullable,
            default_value     => $_->default_value,
            data_type         => $_->data_type,
            size              => $_->size,
            ($_->{extra} ? (extra => $_->{extra}) : ()),
        } }
         } ($table->get_fields);

        $output .= "\n__PACKAGE__->add_columns(";
        foreach my $f (@fields)
        {
            local $Data::Dumper::Terse = 1;
            $output .= "\n    '" . (keys %$f)[0] . "' => " ;
            my $colinfo =
                Data::Dumper->Dump([values %$f],
                                   [''] # keys   %$f]
                                   );
            chomp($colinfo);
            $output .= $colinfo . ",";
        }
        $output .= "\n);\n";

        my $pk = $table->primary_key;
        if($pk)
        {
            my @pk = map { $_->name } ($pk->fields);
            $output .= "__PACKAGE__->set_primary_key(";
            $output .= "'" . join("', '", @pk) . "');\n";
        }

        foreach my $cont ($table->get_constraints)
        {
#            print Data::Dumper::Dumper($cont->type);
            if($cont->type =~ /foreign key/i)
            {
#                 $output .= "\n__PACKAGE__->belongs_to('" .
#                     $cont->fields->[0]->name . "', '" .
#                     "${dbixschema}::" . $cont->reference_table . "');\n";

                $tableextras{$table->name} .= "\n__PACKAGE__->belongs_to('" .
                    $cont->fields->[0]->name . "', '" .
                    "${dbixschema}::" . $cont->reference_table . "');\n";

                my $other = "\n__PACKAGE__->has_many('" .
                    $table->name. "', '" .
                    "${dbixschema}::" . $table->name. "', '" .
                    $cont->fields->[0]->name . "');";
                $tableextras{$cont->reference_table} .= $other;
            }
        }

        $tableoutput{$table->name} .= $output;
    }

    foreach my $to (keys %tableoutput)
    {
        $output .= $tableoutput{$to};
        $schemaoutput .= "\n__PACKAGE__->register_class('${to}', '${dbixschema}::${to}');\n";
    }

    foreach my $te (keys %tableextras)
    {
        $output .= "\npackage ${dbixschema}::$te;\n";
        $output .= $tableextras{$te} . "\n";
#        $tableoutput{$te} .= $tableextras{$te} . "\n";
    }

#    print "$output\n";
    return "${output}\n\n${schemaoutput}\n1;\n";
}
}

=encoding utf-8

=head1 NAME

SQL::Translator::Producer::GraphQL - GraphQL schema producer for SQL::Translator

=begin markdown

# PROJECT STATUS

| OS      |  Build status |
|:-------:|--------------:|
| Linux   | [![Build Status](https://travis-ci.org/graphql-perl/SQL-Translator-Producer-GraphQL.svg?branch=master)](https://travis-ci.org/graphql-perl/SQL-Translator-Producer-GraphQL) |

[![CPAN version](https://badge.fury.io/pl/SQL-Translator-Producer-GraphQL.svg)](https://metacpan.org/pod/SQL::Translator::Producer::GraphQL)

=end markdown

=head1 SYNOPSIS

  use SQL::Translator;
  use SQL::Translator::Producer::GraphQL;
  my $t = SQL::Translator->new( parser => '...' );
  $t->producer('GraphQL');
  $t->translate;

=head1 DESCRIPTION

This module will produce a L<GraphQL::Schema> from the given
L<SQL::Translator::Schema>. It does this by first
turning it into a L<DBIx::Class::Schema> using
L<SQL::Translator::Producer::DBIx::Class::File>, then passing it to
L<GraphQL::Plugin::Convert::DBIC/to_graphql>.

=head1 ARGUMENTS

Currently none.

=head1 DEBUGGING

To debug, set environment variable C<GRAPHQL_DEBUG> to a true value.

=head1 AUTHOR

Ed J, C<< <etj at cpan.org> >>

Based heavily on L<SQL::Translator::Producer::DBIxSchemaDSL>.

=head1 LICENSE

Copyright (C) Ed J

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
