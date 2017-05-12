#define PERL_constant_NOTFOUND	1
#define PERL_constant_NOTDEF	2
#define PERL_constant_ISIV	3
#define PERL_constant_ISNO	4
#define PERL_constant_ISNV	5
#define PERL_constant_ISPV	6
#define PERL_constant_ISPVN	7
#define PERL_constant_ISSV	8
#define PERL_constant_ISUNDEF	9
#define PERL_constant_ISUV	10
#define PERL_constant_ISYES	11

#ifndef NVTYPE
typedef double NV; /* 5.6 and later define NVTYPE, and typedef NV to it.  */
#endif
#ifndef aTHX_
#define aTHX_ /* 5.6 or later define this for threading support.  */
#endif
#ifndef pTHX_
#define pTHX_ /* 5.6 or later define this for threading support.  */
#endif

static int
constant_13 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     SERVICE_FILES SERVICE_MUSIC SERVICE_TASKS */
  /* Offset 11 gives the best switch position.  */
  switch (name[11]) {
  case 'E':
    if (memEQ(name, "SERVICE_FILES", 13)) {
    /*                          ^        */
#ifdef SERVICE_FILES
      *iv_return = SERVICE_FILES;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "SERVICE_MUSIC", 13)) {
    /*                          ^        */
#ifdef SERVICE_MUSIC
      *iv_return = SERVICE_MUSIC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'K':
    if (memEQ(name, "SERVICE_TASKS", 13)) {
    /*                          ^        */
#ifdef SERVICE_TASKS
      *iv_return = SERVICE_TASKS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_14 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     SERVICE_EMAILS SERVICE_IMAGES SERVICE_VIDEOS */
  /* Offset 11 gives the best switch position.  */
  switch (name[11]) {
  case 'E':
    if (memEQ(name, "SERVICE_VIDEOS", 14)) {
    /*                          ^         */
#ifdef SERVICE_VIDEOS
      *iv_return = SERVICE_VIDEOS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'G':
    if (memEQ(name, "SERVICE_IMAGES", 14)) {
    /*                          ^         */
#ifdef SERVICE_IMAGES
      *iv_return = SERVICE_IMAGES;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "SERVICE_EMAILS", 14)) {
    /*                          ^         */
#ifdef SERVICE_EMAILS
      *iv_return = SERVICE_EMAILS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_17 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     SERVICE_BOOKMARKS SERVICE_DOCUMENTS SERVICE_PLAYLISTS SERVICE_VFS_FILES
     SERVICE_VFS_MUSIC */
  /* Offset 14 gives the best switch position.  */
  switch (name[14]) {
  case 'L':
    if (memEQ(name, "SERVICE_VFS_FILES", 17)) {
    /*                             ^         */
#ifdef SERVICE_VFS_FILES
      *iv_return = SERVICE_VFS_FILES;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "SERVICE_DOCUMENTS", 17)) {
    /*                             ^         */
#ifdef SERVICE_DOCUMENTS
      *iv_return = SERVICE_DOCUMENTS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "SERVICE_BOOKMARKS", 17)) {
    /*                             ^         */
#ifdef SERVICE_BOOKMARKS
      *iv_return = SERVICE_BOOKMARKS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "SERVICE_PLAYLISTS", 17)) {
    /*                             ^         */
#ifdef SERVICE_PLAYLISTS
      *iv_return = SERVICE_PLAYLISTS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SERVICE_VFS_MUSIC", 17)) {
    /*                             ^         */
#ifdef SERVICE_VFS_MUSIC
      *iv_return = SERVICE_VFS_MUSIC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_18 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     SERVICE_TEXT_FILES SERVICE_VFS_IMAGES SERVICE_VFS_VIDEOS */
  /* Offset 13 gives the best switch position.  */
  switch (name[13]) {
  case 'F':
    if (memEQ(name, "SERVICE_TEXT_FILES", 18)) {
    /*                            ^           */
#ifdef SERVICE_TEXT_FILES
      *iv_return = SERVICE_TEXT_FILES;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "SERVICE_VFS_VIDEOS", 18)) {
    /*                            ^           */
#ifdef SERVICE_VFS_VIDEOS
      *iv_return = SERVICE_VFS_VIDEOS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "SERVICE_VFS_IMAGES", 18)) {
    /*                            ^           */
#ifdef SERVICE_VFS_IMAGES
      *iv_return = SERVICE_VFS_IMAGES;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_21 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     DATA_STRING_INDEXABLE SERVICE_CONVERSATIONS SERVICE_VFS_DOCUMENTS */
  /* Offset 13 gives the best switch position.  */
  switch (name[13]) {
  case 'N':
    if (memEQ(name, "DATA_STRING_INDEXABLE", 21)) {
    /*                            ^              */
#ifdef DATA_STRING_INDEXABLE
      *iv_return = DATA_STRING_INDEXABLE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "SERVICE_VFS_DOCUMENTS", 21)) {
    /*                            ^              */
#ifdef SERVICE_VFS_DOCUMENTS
      *iv_return = SERVICE_VFS_DOCUMENTS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "SERVICE_CONVERSATIONS", 21)) {
    /*                            ^              */
#ifdef SERVICE_CONVERSATIONS
      *iv_return = SERVICE_CONVERSATIONS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant (pTHX_ const char *name, STRLEN len, IV *iv_return) {
  /* Initially switch on the length of the name.  */
  /* When generated this function returned values for the list of names given
     in this section of perl code.  Rather than manually editing these functions
     to add or remove constants, which would result in this comment and section
     of code becoming inaccurate, we recommend that you edit this section of
     code, and use it to regenerate a new set of constant functions which you
     then use to replace the originals.

     Regenerate these constant functions by feeding this entire source file to
     perl -x

#!/usr/bin/perl -w
use ExtUtils::Constant qw (constant_types C_constant XS_constant);

my $types = {map {($_, 1)} qw(IV)};
my @names = (qw(DATA_DATE DATA_NUMERIC DATA_STRING DATA_STRING_INDEXABLE
	       SERVICE_APPLICATIONS SERVICE_APPOINTMENTS SERVICE_BOOKMARKS
	       SERVICE_CONTACTS SERVICE_CONVERSATIONS SERVICE_DEVELOPMENT_FILES
	       SERVICE_DOCUMENTS SERVICE_EMAILATTACHMENTS SERVICE_EMAILS
	       SERVICE_FILES SERVICE_FOLDERS SERVICE_HISTORY SERVICE_IMAGES
	       SERVICE_MUSIC SERVICE_OTHER_FILES SERVICE_PLAYLISTS
	       SERVICE_PROJECTS SERVICE_TASKS SERVICE_TEXT_FILES
	       SERVICE_VFS_DEVELOPMENT_FILES SERVICE_VFS_DOCUMENTS
	       SERVICE_VFS_FILES SERVICE_VFS_FOLDERS SERVICE_VFS_IMAGES
	       SERVICE_VFS_MUSIC SERVICE_VFS_OTHER_FILES SERVICE_VFS_TEXT_FILES
	       SERVICE_VFS_VIDEOS SERVICE_VIDEOS));

print constant_types(); # macro defs
foreach (C_constant ("LibTracker::Client", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "#### XS Section:\n";
print XS_constant ("LibTracker::Client", $types);
__END__
   */

  switch (len) {
  case 9:
    if (memEQ(name, "DATA_DATE", 9)) {
#ifdef DATA_DATE
      *iv_return = DATA_DATE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 11:
    if (memEQ(name, "DATA_STRING", 11)) {
#ifdef DATA_STRING
      *iv_return = DATA_STRING;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 12:
    if (memEQ(name, "DATA_NUMERIC", 12)) {
#ifdef DATA_NUMERIC
      *iv_return = DATA_NUMERIC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 13:
    return constant_13 (aTHX_ name, iv_return);
    break;
  case 14:
    return constant_14 (aTHX_ name, iv_return);
    break;
  case 15:
    /* Names all of length 15.  */
    /* SERVICE_FOLDERS SERVICE_HISTORY */
    /* Offset 8 gives the best switch position.  */
    switch (name[8]) {
    case 'F':
      if (memEQ(name, "SERVICE_FOLDERS", 15)) {
      /*                       ^             */
#ifdef SERVICE_FOLDERS
        *iv_return = SERVICE_FOLDERS;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'H':
      if (memEQ(name, "SERVICE_HISTORY", 15)) {
      /*                       ^             */
#ifdef SERVICE_HISTORY
        *iv_return = SERVICE_HISTORY;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 16:
    /* Names all of length 16.  */
    /* SERVICE_CONTACTS SERVICE_PROJECTS */
    /* Offset 10 gives the best switch position.  */
    switch (name[10]) {
    case 'N':
      if (memEQ(name, "SERVICE_CONTACTS", 16)) {
      /*                         ^            */
#ifdef SERVICE_CONTACTS
        *iv_return = SERVICE_CONTACTS;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'O':
      if (memEQ(name, "SERVICE_PROJECTS", 16)) {
      /*                         ^            */
#ifdef SERVICE_PROJECTS
        *iv_return = SERVICE_PROJECTS;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 17:
    return constant_17 (aTHX_ name, iv_return);
    break;
  case 18:
    return constant_18 (aTHX_ name, iv_return);
    break;
  case 19:
    /* Names all of length 19.  */
    /* SERVICE_OTHER_FILES SERVICE_VFS_FOLDERS */
    /* Offset 15 gives the best switch position.  */
    switch (name[15]) {
    case 'D':
      if (memEQ(name, "SERVICE_VFS_FOLDERS", 19)) {
      /*                              ^          */
#ifdef SERVICE_VFS_FOLDERS
        *iv_return = SERVICE_VFS_FOLDERS;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'I':
      if (memEQ(name, "SERVICE_OTHER_FILES", 19)) {
      /*                              ^          */
#ifdef SERVICE_OTHER_FILES
        *iv_return = SERVICE_OTHER_FILES;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 20:
    /* Names all of length 20.  */
    /* SERVICE_APPLICATIONS SERVICE_APPOINTMENTS */
    /* Offset 17 gives the best switch position.  */
    switch (name[17]) {
    case 'N':
      if (memEQ(name, "SERVICE_APPOINTMENTS", 20)) {
      /*                                ^         */
#ifdef SERVICE_APPOINTMENTS
        *iv_return = SERVICE_APPOINTMENTS;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'O':
      if (memEQ(name, "SERVICE_APPLICATIONS", 20)) {
      /*                                ^         */
#ifdef SERVICE_APPLICATIONS
        *iv_return = SERVICE_APPLICATIONS;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 21:
    return constant_21 (aTHX_ name, iv_return);
    break;
  case 22:
    if (memEQ(name, "SERVICE_VFS_TEXT_FILES", 22)) {
#ifdef SERVICE_VFS_TEXT_FILES
      *iv_return = SERVICE_VFS_TEXT_FILES;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 23:
    if (memEQ(name, "SERVICE_VFS_OTHER_FILES", 23)) {
#ifdef SERVICE_VFS_OTHER_FILES
      *iv_return = SERVICE_VFS_OTHER_FILES;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 24:
    if (memEQ(name, "SERVICE_EMAILATTACHMENTS", 24)) {
#ifdef SERVICE_EMAILATTACHMENTS
      *iv_return = SERVICE_EMAILATTACHMENTS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 25:
    if (memEQ(name, "SERVICE_DEVELOPMENT_FILES", 25)) {
#ifdef SERVICE_DEVELOPMENT_FILES
      *iv_return = SERVICE_DEVELOPMENT_FILES;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 29:
    if (memEQ(name, "SERVICE_VFS_DEVELOPMENT_FILES", 29)) {
#ifdef SERVICE_VFS_DEVELOPMENT_FILES
      *iv_return = SERVICE_VFS_DEVELOPMENT_FILES;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

