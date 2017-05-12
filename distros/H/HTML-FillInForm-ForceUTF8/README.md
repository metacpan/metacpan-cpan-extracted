# NAME

HTML::FillInForm::ForceUTF8 -  FillInForm with utf8 encoding

# SYNOPSIS

    use HTML::FillInForm::ForceUTF8;

    my $fif = HTML::FillInForm::ForceUTF8->new;

    my $fdat;
    $fdat->{foo} = "\x{306a}\x{304c}\x{306e}"; #Unicode flagged
    $fdat->{bar} = "\xe3\x81\xaa\xe3\x81\x8c\xe3\x81\xae"; # UTF8 bytes

    my $output = $fif->fill(
      scalarref => \$html,
      fdat => $fdat
    );

# DESCRIPTION

HTML::FillInForm::ForceUTF8 is a subclass of HTML::FillInForm that forces utf8 flag on html and parameters. This allows you to prevent filling garbled result.

# SEE ALSO

[HTML::FillInForm](http://search.cpan.org/perldoc?HTML::FillInForm)

# LICENSE

Copyright (C) Masahiro Nagano.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Masahiro Nagano <kazeburo@gmail.com>
