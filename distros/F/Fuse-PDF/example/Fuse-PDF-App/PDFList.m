//
//  PDFList.m
//  Fuse-PDF-App
//
//  Created by Chris Dolan on 12/12/07.
//  Copyright 2007 Clotho Advanced Media, Inc.. All rights reserved.
//

#import "PDFList.h"


@implementation PDFList


-(id)init {
   array = [[NSMutableArray alloc] initWithCapacity:1];
   return self;
}

-(void)dealloc {
   [array release];
   [super dealloc];
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView {
   return [array count]/2;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
   return [array objectAtIndex:rowIndex*2];
}

-(NSMutableArray *) array {
   return array;
}

@end
