[![Automated Tests](https://github.com/bodo-hugo-barwich/file-driver-pl/actions/workflows/automated_testing.yml/badge.svg)](https://github.com/bodo-hugo-barwich/file-driver-pl/actions/workflows/automated_testing.yml)
[![Publish new Release](https://github.com/bodo-hugo-barwich/file-driver-pl/actions/workflows/publish_release.yml/badge.svg)](https://github.com/bodo-hugo-barwich/file-driver-pl/actions/workflows/publish_release.yml)

# File::Access::Driver

File::Access::Driver - Library to access files in an easy and straight forward way

This library is full fleshed "_batteries included_" solution 
to ease up the work with files.

It does not crash but instead reports errors in the in-built error report.

On writing the files if directories do not exist they will be created automatically.

On reading when a file does not exist it does not produce an exception but an empty
string. But in the error report it can be seen, that the file did not exist.

# Features

Some important Features are:
- Automatic file creation on write
- Persistent file access (instead of opening and closing constantly)
- Resilent design (reading on non existing files does not crash)
- In-built error report 
- Avoids copy-in-memory operations

# Usage

The `File::Access::Driver` can be used to **read a file** as seen in the "_File Read_" test:

```perl
        use File::Access::Driver;

        # Make sure the file exists
        is( $driver->Exists(), 1, "File Exist: File exists already" );
        isnt( $driver->getFileSize(), 0, "File Size: File is not empty" );

        is( $driver->Read(), 1, "File Read: Read operation correct" );

        printf(
            "Test File Read - File '%s': Read finished with [%d]\n",
            $driver->getFileName(),
            $driver->getErrorCode()
        );
        printf(
            "Test File Read - File '%s': Read Report:\n'%s'\n",
            $driver->getFileName(),
            ${ $driver->getReportString() }
        );
        printf(
            "Test File Read - File '%s': Read Error:\n'%s'\n",
            $driver->getFileName(),
            ${ $driver->getErrorString() }
        );

        is( $driver->getErrorCode(),        0,  "Read Error Code: No errors have occurred" );
        is( ${ $driver->getErrorString() }, '', "Read Error Message: No errors are reported" );

        my $content = $driver->getContent();

        printf(
            "Test File Read - File '%s': Read Content (%s):\n'%s'\n",
            $driver->getFileName(),
            length( ${$content} ),
            ${$content}
        );

        isnt( length( ${$content} ), 0,  "File Content: Length is correct" );
        isnt( ${$content},           '', "File Content: is not empty" );

        my $content_array = $driver->getContentArray();

        printf(
            "Test File Read - File '%s': Read Content Lines (%s):\n'%s'\n",
            $driver->getFileName(),
            scalar( @{$content_array} ),
            join( '|', @{$content_array} )
        );

        is( scalar( @{$content_array} ), 6, "File Content Lines: 6 Lines were read" );
```

The `File::Access::Driver` can be used to **write a file** as seen in the "_File Write_" test:

```perl
        use File::Access::Driver;

        my $driver = File::Access::Driver->new( 'filepath' => $spath . 'files/out/testfile_out.txt' );

        # Make sure the file does not exist
        is( $driver->Delete(), 1, "File Delete: Delete operation 1 correct" );
        is( $driver->Exists(), 0, "File Exist: File does not exist anymore" );

        $driver->writeContent(q(This is the multi line content for the test file.

It will be written into the test file.
The file should only contain this text.
Also the file should be created.
));

        printf(
            "Test File Exists - File '%s': Write finished with [%d]\n",
            $driver->getFileName(),
            $driver->getErrorCode()
        );
        printf(
            "Test File Exists - File '%s': Write Report:\n'%s'\n",
            $driver->getFileName(),
            ${ $driver->getReportString() }
        );
        printf(
            "Test File Exists - File '%s': Write Error:\n'%s'\n",
            $driver->getFileName(),
            ${ $driver->getErrorString() }
        );

        is( $driver->getErrorCode(),        0,  "Write Error Code: No errors have occurred" );
        is( ${ $driver->getErrorString() }, '', "Write Error Message: No errors are reported" );

        is( $driver->Exists(), 1, "File Exist: File does exist now" );
        isnt( $driver->getFileSize(), 0, "File Size: File is not empty anymore" );

```