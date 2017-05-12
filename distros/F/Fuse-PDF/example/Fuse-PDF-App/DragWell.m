//
//  DragWell.m
//  Fuse-PDF-App
//
//  Created by Chris Dolan on 12/12/07.
//  Copyright 2007 Clotho Advanced Media, Inc.. All rights reserved.
//

#import "DragWell.h"


@implementation DragWell

-(void)setCallback:(Callback*)cb {
   [callback release];
   callback = cb;
   [callback retain];
}

-(void)highlight:(BOOL)b {
   //[[self contentView] setHidden:!b];
}

- (NSArray *) getFilenamesFromPBoard:(id <NSDraggingInfo>)sender {
   if ([sender draggingSourceOperationMask] & NSDragOperationLink) {
      NSPasteboard *pboard = [sender draggingPasteboard];
      if ( [[pboard types] containsObject:NSFilenamesPboardType] ) {
         NSArray *arr = [pboard propertyListForType:NSFilenamesPboardType];
         if (arr) {
            return arr;
            //return [arr pathsMatchingExtensions:[NSArray arrayWithObject:@"pdf"]];
         }
      }
   }
   return nil;
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
   printf("drag entered\n");
   //NSPasteboard *pboard = [sender draggingPasteboard];
   NSArray *filenames = [self getFilenamesFromPBoard:sender];
   if ( filenames ) {
      NSString *filename = [filenames objectAtIndex:0];
      if (filename) {
         printf("PDF? %s\n", [filename UTF8String]);
         if (NSOrderedSame == [[filename pathExtension] caseInsensitiveCompare:@"pdf"]) {
            [self highlight:YES];
            return NSDragOperationLink;
         }
      }
   }
   return NSDragOperationNone;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender {
   printf("drag exited\n");
   [self highlight:NO];
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
   BOOL accept = NO;
   NSArray *filenames = [self getFilenamesFromPBoard:sender];
   int i;
   for (i = 0; i < [filenames count]; ++i) {
      NSString *filename = [filenames objectAtIndex:i];
      if (filename) {
         if (NSOrderedSame == [[filename pathExtension] caseInsensitiveCompare:@"pdf"]) {
            [callback invoke:filename];
            accept = YES;
         }
      }
   }
   return accept;
}

@end
