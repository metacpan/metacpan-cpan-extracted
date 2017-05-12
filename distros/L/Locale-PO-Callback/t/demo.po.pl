$VAR1 = [
          {
            'headers' => {
                           'last-translator' => 'Thomas Thurman <marnanel@cpan.org>',
                           'content-type' => 'text/plain; charset=UTF-8',
                           'language-team' => 'test <test@example.org>',
                           'po-revision-date' => '1975-01-30 00:00 +0000',
                           'mime-version' => '1.0',
                           'project-id-version' => 'Demo of a .po file',
                           'content-transfer-encoding' => '8bit'
                         },
            'header_order' => [
                                'Project-Id-Version',
                                'PO-Revision-Date',
                                'Last-Translator',
                                'Language-Team',
                                'MIME-Version',
                                'Content-Type',
                                'Content-Transfer-Encoding'
                              ],
            'type' => 'header',
            'comments' => '# Comments at the top of the file.
'
          },
          {
            'locations' => [],
            'flags' => {},
            'msgid' => 'This is a message',
            'msgstr' => 'This is a translation',
            'type' => 'translation',
            'comments' => ''
          },
          {
            'locations' => [],
            'flags' => {},
            'msgid' => 'This message has no translation yet',
            'msgstr' => '',
            'type' => 'translation',
            'comments' => ''
          },
          {
            'locations' => [],
            'flags' => {
                         'fuzzy' => 1
                       },
            'msgid' => 'This message is interesting',
            'msgstr' => 'but the translation is possibly wrong',
            'type' => 'translation',
            'comments' => ''
          },
          {
            'locations' => [
                             [
                               'src/test.c',
                               '177'
                             ]
                           ],
            'flags' => {
                         'fuzzy' => 1
                       },
            'msgid' => 'This message came from a specific line',
            'msgstr' => 'in a source file, and is fuzzy',
            'type' => 'translation',
            'comments' => ''
          }
        ];
