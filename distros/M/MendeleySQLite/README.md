MendeleSQLite
=============

A collection of tools written in Perl for working directly with the Mendeley client SQLite database. 

For more information on how to locate the Mendeley Desktop database: http://support.mendeley.com/customer/portal/articles/227951-how-do-i-locate-mendeley-desktop-database-files-on-my-computer-

While most of these tools operate on a read-only basis, always make a backup of your data before hand: either use the built-in desktop client's backup function or make a copy of the file itself. 

For more information on how to backup your local database: http://www.mendeley.com/faq/#howto-backup-data

Tools
________

Generate an HTML tagcloud of all your keywords:

```shell
perl -Ilib bin/maketagcloud.pl --dbfile=moo.sqlite --mode=keywords > cloud.html
```

Transfer document keywords to tags (useful after migrating into Mendeley):

```shell
perl -Ilib bin/migrate_keywords_to_tags.pl --dbfile=moo.sqlite
```

