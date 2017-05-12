//
//  Callback.m
//  MediaLandscape
//
//  Created by Chris Dolan on 4/28/06.
//  Copyright 2006 Clotho Advanced Media, Inc.. All rights reserved.
//

#import "Callback.h"


@implementation Callback

+(id) create:(id)obj method:(SEL)method
{
   return [[Callback alloc] init:obj method:method data:nil];
}
+(id) create:(id)obj method:(SEL)method data:(id)data
{
   return [[Callback alloc] init:obj method:method data:data];
}
-(id) init:(id)obj method:(SEL)method
{
   return [self init:obj method:method data:nil];
}
-(id) init:(id)obj method:(SEL)method data:(id)data
{
   callbackObj    = obj;
   callbackMethod = method;
   callbackData   = data;
   [callbackObj  retain];
   [callbackData retain];
   return self;
}
-(void) dealloc
{
   [callbackObj  release];
   [callbackData release];
	[super dealloc];
}
-(void) invoke: (id)result
{
   [callbackObj performSelector:callbackMethod withObject:result withObject:callbackData];
}

@end
