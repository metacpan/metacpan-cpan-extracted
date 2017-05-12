//
//  BundledTask.m
//  MediaLandscape
//
//  Created by Chris Dolan on 4/27/06.
//  Copyright 2006 Clotho Advanced Media Inc. All rights reserved.
//

#import "BundledTask.h"

static NSMutableArray *runningTasks = nil;

@implementation BundledTask

+ (id) run:(NSArray *)cmd
{
   BundledTask *t = [[[BundledTask alloc] initWithCmd:cmd] autorelease];
   [t start];
   return t;
}

+ (id) run:(NSArray *)cmd callback:(Callback *)cb
{
   BundledTask *t = [[[BundledTask alloc] initWithCmd:cmd] autorelease];
   [t start:cb];
   return t;
}

- (id) initWithCmd:(NSArray *)cmd
{
   return [self initWithCmd:cmd fromBundle:[NSBundle mainBundle]];
}

- (id) initWithCmd:(NSArray *)cmd fromBundle:(NSBundle *)bundle
{
   task = nil;
   NSString *exe = [cmd objectAtIndex:0];
   if ([exe isAbsolutePath])
   {
      absoluteCmd = cmd;
   }
   else
   {
      // Prepend the Resources directory to the exe of the cmd array
      NSRange argrange;
      argrange.location = 1;
      argrange.length = [cmd count] - 1;
      NSArray *args = [cmd subarrayWithRange:argrange];
      NSString *resourcePath = [bundle resourcePath];
      NSString *absexe = [NSString pathWithComponents:[NSArray arrayWithObjects:resourcePath, exe, nil]];
      absoluteCmd = [[NSArray arrayWithObject: absexe] arrayByAddingObjectsFromArray:args];
   }
   //printf("Preparing to run executable %s\n", [[absoluteCmd objectAtIndex:0] UTF8String]);
   [absoluteCmd retain];
   
   if (![[NSFileManager defaultManager] fileExistsAtPath:[absoluteCmd objectAtIndex:0]])
   {
      printf("Error: command does not exist: %s\n",  [[absoluteCmd componentsJoinedByString:@" "] UTF8String]);
   }
   
   return self;
}

- (void)setVerbose:(BOOL)verbose
{
   isVerbose = verbose;
}

- (void)start
{
   [self start:nil];
}
- (void)start:(Callback *)cb
{
   result = nil;
   if (isVerbose)
      printf("start task '%s'\n", [[absoluteCmd componentsJoinedByString:@" "] UTF8String]);
   [callback release];
   callback = cb;
   [callback retain];
   [task release];
   task = [[TaskWrapper alloc] initWithController:self arguments:absoluteCmd];
   //printf("About to start running...\n");
   [task startProcess];
   //printf("Add to list...\n");

   if (!runningTasks)
       runningTasks = [[NSMutableArray alloc] init];
   [runningTasks addObject:self];
   //printf("%d running tasks\n", [runningTasks count]);
}
- (NSString *)startAndWait
{
   [self start:nil];
   if (isVerbose)
      printf("Waiting...\n");
   [task waitUntilExit];
   if (isVerbose)
      printf("done waiting\n");
   return result;
}

- (void)halt
{
   printf("halt!\n");
   if (isRunning)
      [task stopProcess];
}

- (void)dealloc
{
   [absoluteCmd release];
   [result release];
   [callback release];
   [task autorelease];
	[super dealloc];
}

- (void)appendOutput:(NSString *)output
{
   if (isVerbose)
      printf("%s", [output UTF8String]);
   NSString *newstr = result ? [result stringByAppendingString: output] : output;
   [result release];
   result = [newstr retain];
}

- (BOOL)isRunning
{
   return isRunning;
}

// This method is a callback which your controller can use to do other initialization when a process
// is launched.
- (void)processStarted
{
   isRunning = YES;
}

// This method is a callback which your controller can use to do other cleanup when a process
// is halted.
- (void)processFinished
{
   if (isRunning)
   {
      isRunning = NO;
      if (isVerbose)
         printf("end task '%s'\n", [[absoluteCmd componentsJoinedByString:@" "] UTF8String]);
      [callback invoke:result];
      [runningTasks removeObject:self];
      //[task autorelease];
      //task = nil;
   }
}


@end
