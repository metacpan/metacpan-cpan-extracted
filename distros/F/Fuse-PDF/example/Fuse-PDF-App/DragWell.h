//
//  DragWell.h
//  Fuse-PDF-App
//
//  Created by Chris Dolan on 12/12/07.
//  Copyright 2007 Clotho Advanced Media, Inc.. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Callback.h";

@interface DragWell : NSBox {
   Callback *callback;
}
-(void)setCallback:(Callback*)cb;

@end
