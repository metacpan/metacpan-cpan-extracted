/* main.c: PerlWrapper main source file
 * ------------------------------------------------------------------------
 * Starts a Perl interpreter, sets a few variables and library paths.
 * Executes 'start.pl'.
 * ------------------------------------------------------------------------
 * $Id: main.c 11 2004-10-17 22:19:26Z crenz $
 * Copyright (C) 2004 Christian Renz <crenz@web42.com>.
 * All rights reserved.
 */
 
#include <unistd.h>
#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <Carbon/Carbon.h> // kAlertStopAlert
#include <perlinterpreter.h>

int get_bundle_path(char sPath[1024]) {
	CFBundleRef mainBundle = CFBundleGetMainBundle();
	CFURLRef myURL;
	FSRef fsref;

	myURL = CFBundleCopyBundleURL(mainBundle);
	if (!CFURLGetFSRef (myURL, &fsref)) {
		printf("[Wrapped Perl Application] Error getting FSRef\n");
		return 1;
	}
	FSRefMakePath(&fsref, (UInt8 *) sPath, 1023);

	return 0;
}

int get_resource_path(char sPath[1024]) {
	CFBundleRef mainBundle = CFBundleGetMainBundle();
	CFURLRef myURL;
	FSRef fsref;

	myURL = CFBundleCopyResourcesDirectoryURL(mainBundle);
	if (!CFURLGetFSRef (myURL, &fsref)) {
		printf("[Wrapped Perl Application] Error getting FSRef\n");

		return 1;
	}
	FSRefMakePath(&fsref, (UInt8 *) sPath, 1023);

	return 0;
}

int main(int argc, char* argv[], char** env) {
	char sPath[1024];
	char source[2200];

	perl_init(&argc,&argv,&env);
	perl_exec("$PerlWrapper::Version = '0.1'");

	// Store bundle path in perl variable
	if (get_bundle_path(sPath))
		return 1;
	sprintf(source,
		"$PerlWrapper::BundlePath = '%s';"
		"$^X = '%s/Contents/MacOS/perl';",
		sPath, sPath);
	perl_exec(source);

	// Change path so dynamic libraries will be found
	chdir(sPath);

	// Store resources path in perl variable
	if (get_resource_path(sPath))
		return 1;
	sprintf(source,
		"$PerlWrapper::ResourcesPath = '%s';"
		"@INC = '%s/Perl-Libraries';",
		sPath, sPath);
	perl_exec(source);

	if (strcmp(strrchr(argv[0], '/') + 1, "perl") == 0) {
		perl_init_argv(argc, argv);
		sprintf(source,
			"eval { require '%s'; 1 } or die",
			argv[1]);
		perl_exec(source);
	}
	else {
		sprintf(source,
			"eval { require '%s/Perl-Source/main.pl' }; $PerlWrapper::Error = $@;",
			sPath);
		perl_exec(source);
	}

	char *err = perl_getstring("PerlWrapper::Error");
	if (err && strlen(err) > 0) {
		CFOptionFlags btnhit;

		printf("[Wrapped Perl Application] Perl Error:\n%s\n", err);
		CFStringRef caption = CFStringCreateWithCString(kCFAllocatorSystemDefault, "Perl Error", kCFStringEncodingUTF8);
		CFStringRef message = CFStringCreateWithCString(kCFAllocatorSystemDefault, err, kCFStringEncodingUTF8);
		CFUserNotificationDisplayAlert(
		    0, kAlertStopAlert, NULL, NULL, NULL, caption, message,
		    NULL, NULL, NULL, &btnhit );
		CFRelease(caption);
		CFRelease(message);
	}
	
	perl_destroy();

	// todo: Get perl's return code
	return 0;
}

/* eof *******************************************************************/
