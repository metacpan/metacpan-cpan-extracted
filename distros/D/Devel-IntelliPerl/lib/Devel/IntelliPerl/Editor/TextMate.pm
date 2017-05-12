package Devel::IntelliPerl::Editor::TextMate;
our $VERSION = '0.04';

use Moose;

use Exporter qw(import);
use Devel::IntelliPerl;

extends 'Devel::IntelliPerl::Editor';

our @EXPORT = qw(run);

has editor => ( isa => 'Str', is => 'ro', default => 'TextMate' );

sub run {
    my ($self) = @_;
    my @source;
    my ( $line_number, $column, $filename ) = @ARGV;
    push( @source, $_ ) while (<STDIN>);
    my $ip = Devel::IntelliPerl->new(
        line_number => $line_number,
        column      => $column + 1,
        source      => join( '', @source ),
        filename => $filename
    );
    my @methods = $ip->methods;
    if(@methods) {
    print map {$_.$/} @methods;
    } elsif (my $error = $ip->error) {
        print '$error$The following error occured:'.$/.$error;
    }
    return;

}

__PACKAGE__->meta->make_immutable;


=head1 NAME

Devel::IntelliPerl::Editor::TextMate - IntelliPerl integration for TextMate

=head1 VERSION

version 0.04

=head1 SYNOPSIS

    #!/usr/bin/env ruby -wKU
    require ENV["TM_SUPPORT_PATH"] + "/lib/ui.rb"
    require ENV["TM_SUPPORT_PATH"] + "/lib/exit_codes.rb"

    out=`perl -MDevel::IntelliPerl::Editor::TextMate -e 'run' $TM_LINE_NUMBER $TM_LINE_INDEX "$TM_FILEPATH" 2>&1`

    if /^\$error\$/.match(out) then
      out = out.sub("$error$", "")
      TextMate.exit_show_tool_tip out
    end

    choices = out.split("\n")
    ENV['TM_CURRENT_WORD'] ||= ""

    if choices.size == 1 then
      print choices.first.sub(ENV['TM_CURRENT_WORD'], "")
    else 
      choice = TextMate::UI.menu(choices)
      if choice then
        print choices[choice].sub(ENV['TM_CURRENT_WORD'], "")
      end
    end

Create a new Command in the Bundle Editor and paste this bash script. Set "Input" to B<Entire Document> and "Output" to B<Insert as Text>.
If you set "Scope Selector" to C<source.perl> this script is run only if you are editing a perl file.

To run this command using a key set "Activation" to "Key Equivalent" and type the desired key in the box next to it.

=head1 METHODS

=head2 editor

Set to C<TextMate>.

=head2 run

This method is exported and invokes L<Devel::IntelliPerl>.

=head1 SEE ALSO

L<http://macromates.com/>, L<Devel::IntelliSense>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Moritz Onken, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut