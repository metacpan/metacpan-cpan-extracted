# SYNOPSIS

    use Dictionary::Cambridge

      my $dictionary = Dictionary::Cambridge->new(
       access_key => $ENV{ACCESS_KEY},
       dictionary => 'british',
       format     => 'xml'
   );

    my $meaning = $dictionary->get_entry("test");

# DESCRIPTION

    A simple module to interact with Cambridge Dictionary API, this module will only be able to get the meaning of the words
    and their relevant examples if they exist. Also this is my first release so please be patient on mistake and errors.

## METHODS
    get\_entry
    params: word to get the meaning of
=head1 SEE ALSO

[http://dictionary-api.cambridge.org/api/resources](http://dictionary-api.cambridge.org/api/resources)
