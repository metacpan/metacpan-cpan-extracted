package EBook::MOBI::Driver::Example;

our $VERSION = '0.72'; # VERSION (hook for Dist::Zilla::Plugin::OurPkgVersion)

use EBook::MOBI::Converter;
use EBook::MOBI::Driver;

our @ISA = ('EBook::MOBI::Driver');

sub parse {
    my ($self, $input) = @_;

    # This module can help me to translate my stuff to html understood by
    # the mopipocket format
    my $converter = EBook::MOBI::Converter->new();

    # Because of "KISS" the module does not do much, but return the
    # converted stuff. So I need to manage the output myself.
    # I'll keep everything in this variable.
    my $mobiFormat = ''; 

    # We have some usefull methods from EBook::MOBI::Driver
    $self->debug_msg("Start parsing...");

    ########################################################################
    # Here is the parsing... for sure this looks different for any other   #
    # format. You might even use an existing parser like e.g. POD::Parser. #
    ########################################################################

    # work on each line, including newline
    while($input =~ /([^\n]+\n?)/g){
        my $line = $1; 

        # this converts every html special char to it's html entity.
        # if your markups format does interfere with html special chars
        # you should call this AFTER parsing.
        my $mobi_line .= $converter->text($line);

        if ($mobi_line =~ /^!(.)!\s+(.*)/) {
            my $cmd = $1; 
            my $txt = $2; 

            $self->debug_msg('work');

            if ($cmd eq 'h')    { $mobiFormat .= $converter->title ($txt)  }
            elsif ($cmd eq 'i') { $mobiFormat .= $converter->italic($txt)
                                         .  $converter->newline();    }   
            elsif ($cmd eq 'b') { $mobiFormat .= $converter->bold  ($txt)
                                         .  $converter->newline();    }
            elsif ($cmd eq ' ') { $mobiFormat .=                    $txt
                                         .  $converter->newline();    }
            else                { $self->debug_msg("Unknown format: $cmd") }
        }
        else {
            $self->debug_msg("Unknown line: $mobi_line");
        }
    }

    $self->debug_msg("...done");

    # and return the complete converted text
    return $mobiFormat;
}

sub set_options {
    my $self = shift;
    $self->debug_msg('this plugin has no options');
}

1;

__END__

=encoding utf8

=head1 NAME

EBook::MOBI::Driver::Example - Example plugin implementation.

This module is just for demonstration.
I invented a very simple markup, which works only line by line, to show how a plugin can be created.

=head1 SYNOPSIS (for users)

If you wan't to run this as a plugin, use this code.
But I can't imagine any situation where this might be the case for real, since this is B<just an example> for a markup which is not actually existing.

 use EBook::MOBI;
 my $book = EBook::MOBI->new();

 my $foomarkup= <<FOOMARKUP;
 !h! This is a Title
 ! ! A normal text line.
 !i! An italic text line.
 ! ! This is just a very simple example of markup.
 !b! Guess what. This is a bold line.
 
 typo : this is ignored
 !U! unknown command
 FOOMARKUP

 $book->add_content( data   => $foomarkup,
                     driver => 'EBook::MOBI::Driver::Example',
                   );

=head1 SYNOPSIS (for developers)

Here you can see how the plugin will be called by L<EBook::MOBI>:

 use EBook::MOBI::Driver::Example;

 my $plugin = EBook::MOBI::Driver::Example->new();

 my $format= <<FOOMARKUP;
 !h! This is a Title
 ! ! A normal text line.
 !i! An italic text line.
 ! ! This is just a very simple example of markup.
 !b! Guess what. This is a bold line.
 
 typo : this is ignored
 !U! unknown command
 FOOMARKUP

 my $mobi_format = $plugin->parse($format);

Please check the source code of this module if you are interested in writing a plugin.
It will be a good and simple example.

=head1 Methods

=head2 parse

This is the method each plugin should provide!
It takes the input format as a string and returns MHTML.

=head2 inherited methods

See L<EBook::MOBI::Driver> for usefull inherited methods.
You can use the debug methods from this module for example.

=head1 COPYRIGHT & LICENSE

Copyright 2012, 2013 Boris Däppen, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms of Artistic License 2.0.

=head1 AUTHOR

Boris Däppen E<lt>bdaeppen.perl@gmail.comE<gt>

=cut

