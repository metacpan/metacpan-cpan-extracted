# Mail::Exim::ACL::Attachments

A Perl module for the [Exim](https://www.exim.org/) mailer that checks email
attachments for blocked filenames.  Common executable, macro-enabled and
archive file formats are identified.

    acl_check_mime:

      warn
        condition = ${if and{{def:mime_filename} \
         {!match{${lc:$mime_filename}}{\N\.((json|xml)\.gz|zip)$\N}} \
         {eq{${perl{check_filename}{$mime_filename}}}{blocked}}}}
        set acl_m_blocked = yes

      warn
        condition = ${if match{${lc:$mime_filename}}{\N\. *(jar|zip)$\N}}
        decode = default
        condition = ${if eq{${perl{check_zip}{$mime_decoded_filename}}} \
                           {blocked}}
        set acl_m_blocked = yes

      accept

## DEPENDENCIES

Requires the Perl modules Exporter and IO::Uncompress::Unzip, which are
distributed with Perl.

## INSTALLATION

Run the following commands to install the software:

    perl Makefile.PL
    make
    make test
    make install

Type the following command to see the module usage information:

    perldoc Mail::Exim::ACL::Attachments

## LICENSE AND COPYRIGHT

Copyright (C) 2022 Andreas Vögele

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
