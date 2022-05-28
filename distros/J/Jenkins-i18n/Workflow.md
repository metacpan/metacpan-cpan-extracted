# Workflow

Under construction.

## Install and configure an Java IDE

Jenkins use Java Properties and Jelly files to implemented internationalization,
and all translations mus be stored in files that uses ISO-8859-1 encoding and
any characters that are not supported by it must be converted to Java entities.

Use your preferred IDE configured to receive UTF-8 as input and automatically
convert to ISO-8859-1 with Java entities: that you save you from a lot of
headaches, leaving you to worry about normally editing the files.

Instructions to setup that will vary depending on the IDE, but here are some
references:

- [IntelliJ IDEA](https://www.jetbrains.com/help/idea/encoding.html#file-encoding-settings)

The IDEA has a good chance to include a spell checking tool, which is a great
addition to the process.

## Run jtt for an overview

Executed with only the `--lang` option, `jtt` will only check all available
translation files and compare those in English with those available (or not) in
the selected language.

This will give you an overview what needs to be done.

My suggestion is to always started with the removal of deprecated keys with the
`--remove` option, so you start cleaning up instead of having to mess with
unnecessary keys text.

## Use Git

Check with Git (`git status`) what changes are being proposed and follow up
from there.

Once a translated file is done, add it with `git add`. I strongly suggest to
work in each file individually so you can get a better control of progress.

### New files

For new files, you will need to open them in the IDE and start the translation.

### Deprecated keys

Review each file that had keys removed, comparing them with the original. It is
possible that you will find lines that were removed because `jtt` identified
them as a empty key (they probably were left overs, without being a well formed
property).

### Removed file

Nothing really to be done in this case, except accept the change with `git add`.

## Compile the Jenkins source code

It's a good idea to recompile the Jenkins source code after changing the
properties, just to be sure everything is fine.

While is always possible to make it with your preferred IDE, using the Maven
CLI might be the easiest way.

First download Maven from https://maven.apache.org/download.cgi.

Then unpack it and follow the instructions detailed in the `README.txt` file.

Once you finish the setup, just move to the Jenkins checkout out Git repository
and execute:

```
mvn -am -pl war,bom -DskipTests -Dspotbugs.skip -Dspotless.check.skip clean install
```

## Tips

### Working in a shell

If you're using a UNIX shell (Bash, Korn, etc), you can use programs like `find`
and `grep` to search files that requires some fixes.

---
**Note**

Since version 0.03, `jtt` includes the `--search` option to do something like
that.

---

For example, let's suppose I know there are remaining "build" English words
spread over Brazilian Portuguese translation properties, so I can do:

```
$ find core/src -type f -name '*pt_BR.properties' | xargs grep -F build -l -i > tmp.txt
```

That creates the text file `tmp.txt` (that I **won't** commit to the repository)
which I can use as a "working queue", since now I will need to review each file.

The next sequence of commands will "pop out" the first filename to `STDOUT`
from the file, allowing me to open the file in the IDE, edit it, then move
to the next file in the "queue".

```
head -1 tmp.txt && sed -i -e '1d' tmp.txt
```
