# NAME

Markdown::ODF - Create ODF documents from Markdown

# SYNOPSIS

    use Markdown::ODF;

    my $convert = Markdown::ODF->new;

    # Optionally use PDF document directly
    my $odf  = $convert->odf;
    my $meta = $odf->meta;
    $meta->set_title("Title for converted document");

    # Optionally set default paragraph style for document
    my $default = odf_create_style(
      'paragraph',
      area     => 'text',
      language => 'en',
      country  => 'GB',
      size     => '11pt',
      font     => 'Arial',
    );
    $odf->insert_style($default, default => TRUE);

    # Add content
    $convert->add_markdown("My markdown with some **bold text**");

# DESCRIPTION

This module converts Markdown to ODF text documents. The ODF document is
accessed using the ["odf"](#odf) method which returns a [ODF::lpOD](https://metacpan.org/pod/ODF%3A%3AlpOD) object
allowing further manipulation of the document.

# METHODS

## odf

Returns the [ODF::lpOD](https://metacpan.org/pod/ODF%3A%3AlpOD) object used for the ODF document.

## add\_markdown($markdown)

Add markdown content as a paragraph to the current ODF page.

## current\_element

Returns the most recent [ODF::lpOD::Element](https://metacpan.org/pod/ODF%3A%3AlpOD%3A%3AElement) that has been written to the document.

## append\_element($element)

Add a ODF::lpOD::Element to the current document and update ["current\_element()"](#current_element).

# LICENSE AND COPYRIGHT

Copyright (c) 2022 Amtivo Group

This program is free software, licensed under the MIT licence.
